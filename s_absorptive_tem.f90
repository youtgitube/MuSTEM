!--------------------------------------------------------------------------------
!
!  Copyright (C) 2017  L. J. Allen, H. G. Brown, A. J. D’Alfonso, S.D. Findlay, B. D. Forbes
!
!  This program is free software: you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation, either version 3 of the License, or
!  (at your option) any later version.
!  
!  This program is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!   
!  You should have received a copy of the GNU General Public License
!  along with this program.  If not, see <http://www.gnu.org/licenses/>.
!                       
!--------------------------------------------------------------------------------

function absorptive_tem_GPU_memory() result(required_memory)
    
    use m_precision, only: fp_kind
    use global_variables, only: nopiy, nopix
    use m_slicing, only: n_slices
    
    implicit none
    
    real(fp_kind) :: required_memory
    
    real(fp_kind) :: array_size
    integer :: array_count
    
    array_size = 4.0_fp_kind * nopiy * nopix
    
    array_count = 4 + 4*n_slices
    
    required_memory = array_count * array_size
    
end function
    


subroutine absorptive_tem
    
    use global_variables
    use m_lens
    use m_user_input
    use m_absorption
    use m_precision
    use output
    use CUFFT
	use cufft_wrapper
    use cuda_array_library
    use cudafor
    use cuda_ms
    use cuda_potential
    use m_slicing
    use cuda_setup
    use m_probe_scan, only: place_probe, probe_initial_position
    use m_tilt, only: tilt_wave_function
    use m_multislice, only: make_absorptive_grates, setup_propagators
    use m_potential, only: precalculate_scattering_factors
    
    implicit none
    
    !dummy variables
    integer(4) :: i_cell,i_slice
    
    !random variables
    integer(4) :: count
       
    !probe variables
    complex(fp_kind) :: psi(nopiy,nopix)
    complex(fp_kind) :: psi_initial(nopiy,nopix)
    complex(fp_kind) :: ctf(nopiy,nopix)
    
    !output
    real(fp_kind) :: cbed(nopiy,nopix)
    real(fp_kind) :: image(nopiy,nopix)
    real(fp_kind) :: tem_image(nopiy,nopix)
    real(fp_kind) :: temp_image(nopiy,nopix)
    
    !diagnostic variables
    real(fp_kind) :: intensity, t1, delta
    
    !output variables
    character(120) :: filename
    
    !device variables
	integer :: plan
	complex(fp_kind),device,allocatable :: prop_d(:,:,:),transf_d(:,:,:)
    complex(fp_kind),device,dimension(nopiy,nopix) :: psi_d, psi_out_d
    
    !device variables for on the fly potentials
    complex(fp_kind),device,allocatable,dimension(:,:) :: bwl_mat_d,inverse_sinc_d,trans_d
    complex(fp_kind),device,allocatable,dimension(:,:,:) :: fz_d,fz_dwf_d,fz_abs_d
        
    real(fp_kind) :: absorptive_tem_GPU_memory

    
    
    call GPU_memory_message(absorptive_tem_GPU_memory(), on_the_fly)
    
    
    
    write(*,*) '|----------------------------------|'
	write(*,*) '|      Pre-calculation setup       |'
	write(*,*) '|----------------------------------|'
    write(*,*)
        
    call calculate_absorption_mu        

    ! Precalculate the scattering factors on a grid
    call precalculate_scattering_factors()
                
    if (on_the_fly) then
        call cuda_setup_many_phasegrate
    else
        call make_absorptive_grates
    endif
    
	call setup_propagators
    
    if (imaging) then
          call make_ctf(ctf,imaging_df)
    endif

    write(*,*) '|--------------------------------|'
	write(*,*) '|      Calculation running       |'
	write(*,*) '|--------------------------------|'
    write(*,*)
    
    
    
	! Plan the fourier transforms
    if (fp_kind.eq.8)then
          call cufftPlan(plan,nopix,nopiy,CUFFT_Z2Z)
	else
          call cufftPlan(plan,nopix,nopiy,CUFFT_C2C)
    endif

	t1 = secnds(0.0)
	
	if (pw_illum) then
        psi_initial = 1.0_fp_kind/sqrt(float(nopiy*nopix))
	else
	    call make_stem_wfn(psi_initial,probe_df,probe_initial_position)
    endif
    
    call tilt_wave_function(psi_initial)
    
    !Copy host arrays to the device
    if (on_the_fly) then
        allocate(bwl_mat_d(nopiy,nopix))
        allocate(inverse_sinc_d(nopiy,nopix))
        allocate(trans_d(nopiy,nopix))
        allocate(fz_d(nopiy,nopix,nt))
        allocate(fz_dwf_d(nopiy,nopix,nt))
        allocate(fz_abs_d(nopiy,nopix,nt))
        fz_d=fz 
        fz_dwf_d=fz_dwf
        fz_abs_d = ci*fz_abs  !make the potential absorptive
        inverse_sinc_d=inverse_sinc
        bwl_mat_d = bwl_mat
    else
	    allocate(transf_d(nopiy,nopix,n_slices))
	    transf_d=transf_absorptive
    endif
    allocate(prop_d(nopiy,nopix,n_slices))
    
    prop_d = prop
    psi_d = psi_initial
    
    do i_cell = 1, n_cells
        do i_slice = 1, n_slices
            
            if(on_the_fly) then
                call cuda_make_abs_potential(trans_d,ccd_slice_array(i_slice),tau_slice(:,:,:,i_slice),nat_slice(:,i_slice),prop_distance(i_slice),plan,fz_d,fz_dwf_d,fz_abs_d,inverse_sinc_d,bwl_mat_d,Volume_array(i_slice))
                call cuda_multiplication<<<blocks,threads>>>(psi_d,trans_d, psi_out_d,1.0_fp_kind,nopiy,nopix)
            else
                call cuda_multiplication<<<blocks,threads>>>(psi_d,transf_d(:,:,i_slice), psi_out_d,1.0_fp_kind,nopiy,nopix)
            endif
            
            call cufftExec(plan,psi_out_d,psi_d,CUFFT_FORWARD)
            call cuda_multiplication<<<blocks,threads>>>(psi_d,prop_d(:,:,i_slice), psi_out_d,normalisation,nopiy,nopix)
            call cufftExec(plan,psi_out_d,psi_d,CUFFT_INVERSE)
        enddo ! End loop over slices
        
        intensity = get_sum(psi_d)
	    write(6,900,advance='no') achar(13), i_cell, intensity
900     format(a1, 1x, 'Cell: ', i5, ' Intensity: ', f12.6)	
        
	enddo ! End loop over cells

    
    
	delta = secnds(t1)
    
    write(*,*) 
    write(*,*) 
    write(*,*) 'Calculation is finished.'
    write(*,*) 
    write(*,*) 'Time elapsed: ', delta, ' seconds.'
    write(*,*)  
    
    open(unit=9834, file=trim(adjustl(output_prefix))//'_timing.txt', access='append')
    write(9834, '(a, g, a, /)') 'The multislice calculation took ', delta, 'seconds.'
    close(9834)
    
    if (fp_kind.eq.8) then
        write(*,*) 'The following files were outputted (as 64-bit big-endian floating point):'
	else
        write(*,*) 'The following files were outputted (as 32-bit big-endian floating point):'
	endif
    write(*,*)
 
    psi = psi_d
    call fft2(nopiy, nopix, psi, nopiy, psi, nopiy)
    cbed = abs(psi)**2

    filename = trim(adjustl(output_prefix)) // '_DiffractionPattern'
    call binary_out_unwrap(nopiy, nopix, cbed, filename)

    ! Image the elastic wave function
    if (imaging) then
          psi = psi*ctf
          call ifft2(nopiy, nopix, psi, nopiy, psi, nopiy)
          tem_image = abs(psi)**2
          
          filename = trim(adjustl(output_prefix)) // '_Image'
          call binary_out(nopiy, nopix, tem_image, filename)
    endif

end subroutine absorptive_tem
