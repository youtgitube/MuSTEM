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

!
!  CUFFT_wrapper.f90
!
!  Free-Format Fortran Source File 
!  Generated by PGI Visual Fortran(R)
!  6/28/2011 12:38:12 PM
!
! Author:	Adrian D'Alfonso
!			uses CUDA fortran
!			requires the module files 
!					1) precision.f90 
!					2) cufft_mod.f90
!
!			contains the subroutine channel_to_exit_abs which is a cuda implementation
!			of the multislice algorithm.
!----------------------------------------------------------------------------------------



module CUFFT_wrapper
use cufft
implicit none
  save

      interface fft1
	  module procedure dfft1d
	  module procedure sfft1d
	end interface fft1

      interface ifft1
	  module procedure dfft1b
	  module procedure sfft1b
	end interface ifft1

      interface fft2
	  module procedure dfft2d
	  module procedure sfft2d
	end interface fft2

      interface ifft2
	  module procedure dfft2b
	  module procedure sfft2b
	end interface ifft2

      interface fft3
	  module procedure dfft3d
	  module procedure sfft3d
	end interface fft3

      interface ifft3
	  module procedure dfft3b
	  module procedure sfft3b
	end interface ifft3



      contains
!	forward 1D transform
	subroutine dfft1d(nopiyb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb
	integer(4) :: nopiy,nopix 
	complex(8),dimension(nopiyb) :: array_in
	complex(8),dimension(nopiyb) :: array_out

	!device arrays
	complex(8),device,dimension(nopiyb) :: array_in_d
	complex(8),device,dimension(nopiyb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,CUFFT_Z2Z)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_FORWARD)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d

    array_out=array_out/(dsqrt(dfloat(nopiyb)))
	return
	end subroutine

!----------------------------------------------------------------------------------------
!	inverse 1D transform
	subroutine dfft1b(nopiyb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb
	integer(4) :: nopiy,nopix 
	complex(8),dimension(nopiyb) :: array_in
	complex(8),dimension(nopiyb) :: array_out

	!device arrays
	complex(8),device,dimension(nopiyb) :: array_in_d
	complex(8),device,dimension(nopiyb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,CUFFT_Z2Z)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_INVERSE)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d

    array_out=array_out/(dsqrt(dfloat(nopiyb)))

	return
	end subroutine
	





!----------------------------------------------------------------------------------------
!	forward 2D transform
	subroutine dfft2d(nopiyb,nopixb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb,nopixb
	integer(4) :: nopiy,nopix 
	complex(8),dimension(nopiyb,nopixb) :: array_in
	complex(8),dimension(nopiyb,nopixb) :: array_out

	!device arrays
	complex(8),device,dimension(nopiyb,nopixb) :: array_in_d
	complex(8),device,dimension(nopiyb,nopixb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopixb,nopiyb,CUFFT_Z2Z)
    !call cufftPlan(plan,nopiyb,nopixb,CUFFT_Z2Z)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_FORWARD)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(dsqrt(dfloat(nopiyb*nopixb)))
	return
	end subroutine

!----------------------------------------------------------------------------------------
!	inverse 2D transform
	subroutine dfft2b(nopiyb,nopixb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb,nopixb
	integer(4) :: nopiy,nopix !dummy
	complex(8),dimension(nopiyb,nopixb) :: array_in
	complex(8),dimension(nopiyb,nopixb) :: array_out

	!device arrays
	complex(8),device,dimension(nopiyb,nopixb) :: array_in_d
	complex(8),device,dimension(nopiyb,nopixb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopixb,nopiyb,CUFFT_Z2Z)
    !call cufftPlan(plan,nopiyb,nopixb,CUFFT_Z2Z)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_INVERSE)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(dsqrt(dfloat(nopiyb*nopixb)))
	return
	end subroutine
	
!----------------------------------------------------------------------------------------
!	forward 3D transform
	subroutine dfft3d(nopiyb,nopixb,nopizb,array_in,nopiy,nopix,array_out,nopiya,nopixa)

	implicit none
	integer	plan
	integer(4) :: nopiya,nopixa,nopiza 
	integer(4) :: nopiyb,nopixb,nopizb
	integer(4) :: nopiy,nopix,nopiz 
	complex(8),dimension(nopiyb,nopixb,nopizb) :: array_in
	complex(8),dimension(nopiyb,nopixb,nopizb) :: array_out

	!device arrays
	complex(8),device,dimension(nopiyb,nopixb,nopizb) :: array_in_d
	complex(8),device,dimension(nopiyb,nopixb,nopizb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,nopixb,nopizb,CUFFT_Z2Z)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_FORWARD)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(dsqrt(dfloat(nopiyb*nopixb*nopizb)))
	return
	end subroutine

!----------------------------------------------------------------------------------------
!	inverse 3D transform
	subroutine dfft3b(nopiyb,nopixb,nopizb,array_in,nopiy,nopix,array_out,nopiya,nopixa)

	implicit none
	integer	plan
	integer(4) :: nopiya,nopixa,nopiza 
	integer(4) :: nopiyb,nopixb,nopizb
	integer(4) :: nopiy,nopix,nopiz 
	complex(8),dimension(nopiyb,nopixb,nopizb) :: array_in
	complex(8),dimension(nopiyb,nopixb,nopizb) :: array_out

	!device arrays
	complex(8),device,dimension(nopiyb,nopixb,nopizb) :: array_in_d
	complex(8),device,dimension(nopiyb,nopixb,nopizb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,nopixb,nopizb,CUFFT_Z2Z)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_INVERSE)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(dsqrt(dfloat(nopiyb*nopixb*nopizb)))
	return
	end subroutine


      !----------------------------------------------------------------------------------------------------------------------------------



      !	forward 1D transform
	subroutine sfft1d(nopiyb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb
	integer(4) :: nopiy,nopix 
	complex(4),dimension(nopiyb) :: array_in
	complex(4),dimension(nopiyb) :: array_out

	!device arrays
	complex(4),device,dimension(nopiyb) :: array_in_d
	complex(4),device,dimension(nopiyb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,CUFFT_C2C)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_FORWARD)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(sqrt(float(nopiyb)))
	return
	end subroutine

!----------------------------------------------------------------------------------------
!	inverse 1D transform
	subroutine sfft1b(nopiyb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb
	integer(4) :: nopiy,nopix 
	complex(4),dimension(nopiyb) :: array_in
	complex(4),dimension(nopiyb) :: array_out

	!device arrays
	complex(4),device,dimension(nopiyb) :: array_in_d
	complex(4),device,dimension(nopiyb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,CUFFT_C2C)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_INVERSE)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(sqrt(float(nopiyb)))
	return
	end subroutine
	





!----------------------------------------------------------------------------------------
!	forward 2D transform
	subroutine sfft2d(nopiyb,nopixb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb,nopixb
	integer(4) :: nopiy,nopix 
	complex(4),dimension(nopiyb,nopixb) :: array_in
	complex(4),dimension(nopiyb,nopixb) :: array_out

	!device arrays
	complex(4),device,dimension(nopiyb,nopixb) :: array_in_d
	complex(4),device,dimension(nopiyb,nopixb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
    call cufftPlan(plan,nopixb,nopiyb,CUFFT_C2C)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_FORWARD)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(sqrt(float(nopiyb*nopixb)))
	return
	end subroutine

!----------------------------------------------------------------------------------------
!	inverse 2D transform
	subroutine sfft2b(nopiyb,nopixb,array_in,nopiy,array_out,nopix)

	implicit none
	integer	plan
	integer(4) :: nopiyb,nopixb
	integer(4) :: nopiy,nopix 
	complex(4),dimension(nopiyb,nopixb) :: array_in
	complex(4),dimension(nopiyb,nopixb) :: array_out

	!device arrays
	complex(4),device,dimension(nopiyb,nopixb) :: array_in_d
	complex(4),device,dimension(nopiyb,nopixb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopixb,nopiyb,CUFFT_C2C)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_INVERSE)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(sqrt(float(nopiyb*nopixb)))
	return
	end subroutine
	
!----------------------------------------------------------------------------------------
!	forward 3D transform
	subroutine sfft3d(nopiyb,nopixb,nopizb,array_in,nopiy,nopix,array_out,nopiya,nopixa)

	implicit none
	integer	plan
	integer(4) :: nopiya,nopixa,nopiza 
	integer(4) :: nopiyb,nopixb,nopizb
	integer(4) :: nopiy,nopix,nopiz 
	complex(4),dimension(nopiyb,nopixb,nopizb) :: array_in
	complex(4),dimension(nopiyb,nopixb,nopizb) :: array_out

	!device arrays
	complex(4),device,dimension(nopiyb,nopixb,nopizb) :: array_in_d
	complex(4),device,dimension(nopiyb,nopixb,nopizb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,nopixb,nopizb,CUFFT_C2C)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_FORWARD)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(sqrt(float(nopiyb*nopixb*nopizb)))
	return
	end subroutine

!----------------------------------------------------------------------------------------
!	inverse 3D transform
	subroutine sfft3b(nopiyb,nopixb,nopizb,array_in,nopiy,nopix,array_out,nopiya,nopixa)

	implicit none
	integer	plan
	integer(4) :: nopiya,nopixa,nopiza 
	integer(4) :: nopiyb,nopixb,nopizb
	integer(4) :: nopiy,nopix,nopiz 
	complex(4),dimension(nopiyb,nopixb,nopizb) :: array_in
	complex(4),dimension(nopiyb,nopixb,nopizb) :: array_out

	!device arrays
	complex(4),device,dimension(nopiyb,nopixb,nopizb) :: array_in_d
	complex(4),device,dimension(nopiyb,nopixb,nopizb) :: array_out_d
	
	!copy data to device
	array_in_d=array_in

	! Initialize the plan
	call cufftPlan(plan,nopiyb,nopixb,nopizb,CUFFT_C2C)

	! Execute FFTs
	call cufftExec(plan,array_in_d,array_out_d,CUFFT_INVERSE)

	! Destroy plans
	call cufftDestroy(plan)

	! Copy results back to host
	array_out=array_out_d
    array_out=array_out/(sqrt(float(nopiyb*nopixb*nopizb)))
	return
	end subroutine
      end module CUFFT_wrapper


