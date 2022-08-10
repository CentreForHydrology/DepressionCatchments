
!  Copyright (C) 2022, Kevin Shook, Centre for Hydrology
!  University of Saskatchewan, 12 Kirk Hall, 101.07 - 121 Research Drive
!  Saskatoon, SK, Canada, S7N 1K2

!  This program is free software; you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation; either version 3 of the License, or
!  (at your option) any later version.
!
!  This program is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.


program DepressionCatchments
!  Reads Lidar DEM and file of filled sloughs
!  For all upland cells, routes flows downhill until destination depression is found
!  Tallies total drainage areas for all depressions

  implicit none
  character(80) :: DEMFileName, depressionFileName, InParameterFileName, OutputFileName
  character(80) :: dem_header_line(8), DirectionFileName, outformat
  real :: dem_header_value(8), max_ht_diff
  real :: cellsize, cellarea, missingvalue, missingarea
  logical :: done
  integer :: i, j, arg_count, numcols, numrows, depressioncount, depressionnum
  real, allocatable, dimension(:,:) :: dem
  integer, allocatable, dimension(:,:) :: direction, depressions
  real, allocatable, dimension(:) ::  depressionareas, basinareas
  integer :: row, col, rowinc, colinc, rowloc, colloc, sloughnum
  integer :: drainrow, draincol, drainloc(2), dir_pointer, distance, max_dir
  integer :: maxdist, rowpos, colpos
  real :: ht_diff

  arg_count = command_argument_count()
  DirectionFileName = 'Directions.asc'
  
  print *, 'DepressionCatchments ver 1.0.'


  if ((arg_count == 0).or.(arg_count/=3)) then
     print *, 'Arguments are: DEM file name, depression file name, Output file name'
     stop
   elseif (arg_count == 1) then
      ! extract arguments
      CALL get_command_argument(1, InParameterFileName)

      open(1, file= InParameterFileName, access="sequential", action = "read")
      read(1,*) DEMFileName
      read(1,*) depressionFileName
      read(1,*) OutputFileName   
      close(1)

      ! write prarameters to stdout
      write(*,*) 'DEM file:', DEMFileName
      write(*,*) 'depression file: ', depressionFileName
      write(*,*) 'Output file: ', OutputFileName      

  else
      call get_command_argument(1, DEMFileName)
      call get_command_argument(2, depressionFileName)
      call get_command_argument(3, OutputFileName)

      ! write prarameters to stdout
      write(*,*) 'DEM file:', DEMFileName
      write(*,*) 'depression file: ', depressionFileName
      write(*,*) 'Output file: ', OutputFileName     

  end if
   ! convert to real and m


  ! now open files to input arrays
  print *, 'Reading DEM data'
  open(1, file= DEMFileName, access="sequential", action = "read")
  do i=1,6
     read(1,*) dem_header_line(i), dem_header_value(i)
  !   print *, dem_header_line(i), dem_header_value(i)
  end do
   

  ! get numbers of rows & cols from header 

  numcols=int(dem_header_value(1))
  numrows=int(dem_header_value(2))
  missingvalue=dem_header_value(6)
  cellsize=dem_header_value(5)
  cellarea=cellsize**2
  write(outformat,'("(",i4,"(1x,i1))")')numcols


  ! set array sizes
  allocate(dem(numrows,numcols))
  allocate(depressions(numrows,numcols))
  allocate(direction(numrows,numcols))

  maxdist = numrows + numcols

  do row =  1, numrows
   read(1,*) (dem(row,col), col=1, numcols)
  end do
  close(1)

  ! find minimum depth
  drainloc = minloc(dem, mask=dem .gt. 0)
  drainrow = drainloc(1)
  draincol = drainloc(2)

  ! read in depressions array
  open(2, file= depressionFileName, access="sequential", action = "read")
  ! read header 1st, then depressions data    
  do i=1,6
      read(2,*) dem_header_line(i), dem_header_value(i)
  end do
  do i =  1, numrows
      read(2,*) (depressions(i,j), j=1, numcols)
  end do
  close (2) 


  ! get total # of depressions

  depressioncount = maxval(depressions)
  allocate(depressionareas(depressioncount))
  allocate(basinareas(depressioncount))
  depressionareas = 0.0
  basinareas = 0.0

  ! find directions of max. gradient
  print *, 'Finding directions'
  done = .false.
  direction = 0

  do col = 1, numcols
  ! print *, 'column ', col
    do row = 1, numrows
      if (dem(row,col) > -1) then
      ! find greatest gradient
        max_ht_diff = 0.0
        dir_pointer = 0
          do rowinc = -1, 1, 1
            rowloc = row + rowinc
            do colinc = -1, 1, 1
              colloc = col + colinc
  !  make sure centre element is not missing
              if ((rowinc /= 0) .or. (colinc /= 0)) then
                dir_pointer = dir_pointer+1
                if ((colloc >= 1).and.(colloc <= numcols) .and. (rowloc >= 1) .and. (rowloc <= numrows)) then  
                  ht_diff = dem(row, col) - dem(rowloc, colloc)
                  if (ht_diff > max_ht_diff) then
                    max_ht_diff = ht_diff
                    max_dir = dir_pointer
                  end if! ht_diff
                end if
              end if  ! row increment
            end do    ! column increment 
          end do      ! row increment
        direction(row,col) = max_dir
      end if              
    end do        ! columns
  end do          ! rows


 print *, "Flow directions found - now finding drainage destination"
  missingarea = 0.0
  print *, 'numcols', numcols, 'numrows', numrows
  do col = 1, numcols
    do row = 1, numrows 
      if ((dem(row,col) > -1).and.(depressions(row,col) == 0)) then
        print *, 'column ', col, 'row ', row, 'depressions =', depressions(row, col)
      ! found a starting point
        colpos = col
        rowpos = row
        dir_pointer = direction(row, col)
        distance = 0
        done = .false.
        do while (.not.(done))
          select case(dir_pointer)
            case(1)
              rowinc = -1
              colinc = -1
            case(2)
              rowinc = -1
              colinc = 0
            case(3)
              rowinc = -1
              colinc = 1
            case(4)
              rowinc = 0
              colinc = -1
            case(5)
              rowinc = 0
              colinc = 1
            case(6)
              rowinc = 1
              colinc = -1
            case(7)
              rowinc = 1
              colinc = 0               
            case(8)
              rowinc = 1
              colinc = 1
          end select
          colpos = colpos + colinc
          rowpos = rowpos + rowinc
          distance = distance + 1

          if ((colpos >= numcols).or.(rowpos >= numrows) .or.(colpos <= 1).or.(rowpos<=1)  &
            .or. (distance > maxdist)) then
            missingarea = missingarea + cellarea
            done = .true.
           print *, 'row=',row,'col=',col,'slough not found'
          else
            sloughnum = depressions(rowpos,colpos)
            print *, 'row=',row,'col=',col,'sloughnum=',sloughnum 
            if (sloughnum > 0) then
              print *, "found slough. distance =", distance, "slough num=", sloughnum
              done = .true.
              basinareas(sloughnum) = basinareas(sloughnum) + cellarea
            elseif (sloughnum < 0) then
              missingarea = missingarea + cellarea
              done = .true.
            end if
          end if  
       end do     ! while - finished tracing this starting point to a depression
         
      end if
    end do        ! columns
  end do          ! rows

  ! now get areas of all depressions

  do depressionnum = 1, depressioncount
     depressionareas(depressionnum) = count(depressions == depressionnum) * cellarea
  end do

  print *, "Area not draining into depressions =", missingarea


  ! finally, write to file
  open(3, file= OutputFileName, access="sequential", action = "write", status="replace")
  write(3,10) "Depression","Depression","Basin"
  write(3,10) "Number","Area","Area"
  do depressionnum = 1, depressioncount
     write(3,20) depressionnum, depressionareas(depressionnum), basinareas(depressionnum)
  end do
  close(3)
  10 format (1x, 3a12)
  20 format (1x, i12,2f12.1)
end program DepressionCatchments
