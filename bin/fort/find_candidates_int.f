      PROGRAM find_candidates_int

      IMPLICIT none
      integer i,j,k,iuv,igam,i4p8,irr,ixx,in,lenact,length,lu_in,ier,icand,filen,is,ie,xpts(2000)
      integer ii1,ii2,ipass,isource,pass2(4000),rr_type(2000),xx_type(2000),xxot_type(10,2000)
      integer nrep(2000),xrayrepeat(2000,2000),ixxss,ixxrep
      real*8 ra,dec,dist,ra_uv(10000),dec_uv(10000),ra_gam(50),dec_gam(50),ra_4p8(500),dec_4p8(500)
      real*8 ra_rr(2000),dec_rr(2000),ra_xx(2000),dec_xx(2000),ra_center,dec_center
      real*4 nh,flux,uflux,lflux,epos,freq,code,radius,flux2nufnu_4p8,fdens,nudens
      real*4 frequency_rr(2000),flux_rr(2000),FluxL_rr(2000),FluxU_rr(2000),poserr_rr(2000)
      real*4 frequency_xx(2000),flux_xx(2000),FluxL_xx(2000),FluxU_xx(2000),poserr_xx(2000)
      real*4 frequency_xxot(10,2000),flux_xxot(10,2000),FluxL_xxot(10,2000),FluxU_xxot(10,2000)
      real*4 frequency_4p8(500),flux_4p8(500),FluxL_4p8(500),FluxU_4p8(500),poserr_xxot(10,2000)
      real*4 poserr_4p8(500),Ferr_4p8(500),poserr_uv(10000)
      real*4 frequency_uv(10000,2),flux_uv(10000,2),FluxL_uv(10000,2),FluxU_uv(10000,2)
      real*4 uvmag(10000,2),uvmagerr(10000,2),slope_gam(50),specerr_gam(50)
      real*4 frequency_gam(50),flux_gam(50),FluxL_gam(50),FluxU_gam(50),poserr_gam(50),Ferr_gam(50)
      real*4 aruv,auvx,min_dist_uv,min_dist_4p8,min_dist_gam,alphar
      character*30 input_file
      character*10 catalog,type_4p8(500)
      character*300 string
      LOGICAL there,ok,found
      ok = .TRUE.
      found = .FALSE.
      min_dist_uv=8./3600.
      min_dist_gam=5./60.
      min_dist_4p8=30./3600.
      flux2nufnu_4p8=4.85E9*1.E-26

      CALL rdforn(string,length)
      CALL rmvlbk(string)
      input_file=string(1:len_trim(string))
      in = index(input_file(1:lenact(input_file)),'.')
      IF (in == 0) input_file(lenact(input_file)+1:lenact(input_file)+4) = '.csv'
      INQUIRE (FILE=input_file,EXIST=there)
      IF (.NOT.there) THEN
         write (*,'('' file '',a,'' not found '')')
     &     input_file(1:lenact(input_file))
         STOP
      ENDIF

      lu_in = 10
      open(lu_in,file=input_file,status='old',iostat=ier)
      open(11,file='no_matched_temp.txt',status='old',iostat=ier)
      open(13,file='find_out_temp.txt',status='old',iostat=ier)
      IF (ier.NE.0) THEN
         write (*,*) ' Error ',ier,' opening file ', input_file
      ENDIF

      icand=0
      ixx=0
      irr=0
      Do WHILE(ok)
         read(11,*,end=100) freq,flux,uflux,lflux,ra,dec,epos,code
         if (code .lt. 10) THEN
            icand=icand+1
            irr=irr+1
            ra_rr(irr)=ra
            dec_rr(irr)=dec
            poserr_rr(irr)=epos
            frequency_rr(irr)=freq
            flux_rr(irr)=flux
            FluxU_rr(irr)=uflux
            FluxL_rr(irr)=lflux
            rr_type(irr)=code
         else if (code .lt. 20) THEN
            icand=icand+1
            ixx=ixx+1
            xpts(ixx)=0
            ra_xx(ixx)=ra
            dec_xx(ixx)=dec
            poserr_xx(ixx)=epos
            frequency_xx(ixx)=freq
            flux_xx(ixx)=flux
            FluxU_xx(ixx)=uflux
            FluxL_xx(ixx)=lflux
            xx_type(ixx)=code
         else
            xpts(ixx)=xpts(ixx)+1
            frequency_xxot(xpts(ixx),ixx)=freq
            flux_xxot(xpts(ixx),ixx)=flux
            FluxU_xxot(xpts(ixx),ixx)=uflux
            FluxL_xxot(xpts(ixx),ixx)=lflux
            xxot_type(xpts(ixx),ixx)=code-50
         endif
      ENDDO
100   continue
c      write(*,*) icand,irr,ixx

      isource=0
      do while(ok)
         read(13,*,end=98) ra,dec,code
         if ((code .gt. 0.) .or. (code .le. -50000.) .or. (code .eq. -9999)) then
            isource=isource+1
         endif
      enddo
98    continue
c      write(*,*) isource

      igam=0
      iuv=0
      i4p8=0
      READ(lu_in,'(a)') string
      is = index(string(1:len(string)),'=')
      ie = index(string(is+5:len(string)),' ') +is+4
      read(string(is+1:ie-1),*) ra_center
      is = index(string(ie+1:len(string)),'=') +ie
      ie = index(string(is+5:len(string)),' ') +is+4
      read(string(is+1:ie-1),*) dec_center
      is = index(string(ie+1:len(string)),'=') +ie
      ie = index(string(is+5:len(string)),' ') +is+4
      read(string(is+1:ie-1),*) radius
      READ(lu_in,'(a)') string !begin reading nh
      is = index(string(1:len(string)),'=')
      ie = index(string(is+5:len(string)),' ') +is+4
      read(string(is+1:ie-1),*) nh
      DO WHILE(ok)
         READ(lu_in,'(a)',end=99) string
         ie=index(string(1:len(string)),',')
         read(string(1:ie-1),*) filen
         is=ie
         ie=index(string(is+1:len(string)),',')+is
         read(string(is+1:ie-1),'(a)') catalog
         is=ie
         ie=index(string(is+1:len(string)),',')+is
         read(string(is+1:ie-1),*) ra
         is=ie
         ie=index(string(is+1:len(string)),',')+is
         read(string(is+1:ie-1),*) dec
         IF ( (catalog(1:3) == 'pmn') .OR. (catalog(1:3) == 'gb6') ) then
            i4p8=i4p8+1
            ra_4p8(i4p8)=ra
            dec_4p8(i4p8)=dec
            if (catalog(1:3) == 'gb6') then
               type_4p8(i4p8)='GB6'
               is=ie
               ie=index(string(is+1:len(string)),',')+is
               if (is .ne. ie-1) read(string(is+1:ie-1),*) poserr_4p8(i4p8)
            else
               type_4p8(i4p8)='PMN'
               poserr_4p8(i4p8)=sqrt((15.*15.)+100.)
            endif
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            if (is .ne. ie-1) read(string(is+1:ie-1),*) flux_4p8(i4p8)
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            if (is .ne. ie-1) read(string(is+1:ie-1),*) Ferr_4p8(i4p8)
            FluxU_4p8(i4p8)=flux_4p8(i4p8)+Ferr_4p8(i4p8)
            FluxL_4p8(i4p8)=flux_4p8(i4p8)-Ferr_4p8(i4p8)
            flux_4p8(i4p8)=flux_4p8(i4p8)*flux2nufnu_4p8
            FluxU_4p8(i4p8)=FluxU_4p8(i4p8)*flux2nufnu_4p8
            FluxL_4p8(i4p8)=FluxL_4p8(i4p8)*flux2nufnu_4p8
            frequency_4p8(i4p8)=4.85e9
         else if (catalog(1:5) == 'galex') then
            iuv=iuv+1
            ra_uv(iuv)=ra
            dec_uv(iuv)=dec
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            read(string(is+1:ie-1),*) uvmag(iuv,1)
            if (uvmag(iuv,1) .le. -999.) uvmag(iuv,1)=0.
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            read(string(is+1:ie-1),*) uvmag(iuv,2)
            if (uvmag(iuv,2) .le. -999.) uvmag(iuv,2)=0.
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            read(string(is+1:ie-1),*) uvmagerr(iuv,1)
            if (uvmagerr(iuv,1) .le. -999.) uvmagerr(iuv,1)=0.
            is=ie
            ie=index(string(is+1:len(string)),' ')+is
            read(string(is+1:ie-1),*) uvmagerr(iuv,2)
            if (uvmagerr(iuv,2) .le. -999.) uvmagerr(iuv,2)=0.
            CALL  mag2flux (nh,uvmag(iuv,2),'fuv',flux_uv(iuv,2),frequency_uv(iuv,2))
         CALL  mag2flux (nh,uvmag(iuv,2)-uvmagerr(iuv,2),'fuv',FluxU_uv(iuv,2),frequency_uv(iuv,2))
         CALL  mag2flux (nh,uvmag(iuv,2)+uvmagerr(iuv,2),'fuv',FluxL_uv(iuv,2),frequency_uv(iuv,2))
            CALL  mag2flux (nh,uvmag(iuv,1),'nuv',flux_uv(iuv,1),frequency_uv(iuv,1))
         CALL  mag2flux (nh,uvmag(iuv,1)-uvmagerr(iuv,1),'nuv',FluxU_uv(iuv,1),frequency_uv(iuv,1))
         CALL  mag2flux (nh,uvmag(iuv,1)+uvmagerr(iuv,1),'nuv',FluxL_uv(iuv,1),frequency_uv(iuv,1))
            poserr_uv(iuv)=1.
         else if (catalog(1:8) == 'fermi8yr') then
            igam=igam+1
            ra_gam(igam)=ra
            dec_gam(igam)=dec
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            if (is .ne. ie-1) read(string(is+1:ie-1),*) poserr_gam(igam)
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            if (is .ne. ie-1) read(string(is+1:ie-1),*) flux_gam(igam)
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            if (is .ne. ie-1) read(string(is+1:ie-1),*) Ferr_gam(igam)
            is=ie
            ie=index(string(is+1:len(string)),',')+is
            if (is .ne. ie-1) read(string(is+1:ie-1),*) slope_gam(igam)
            is=ie
            ie=index(string(is+1:len(string)),' ')+is
            if (is .ne. ie-1) read(string(is+1:ie-1),*) specerr_gam(igam)
            FluxU_gam(igam)=flux_gam(igam)+Ferr_gam(igam)
            FluxL_gam(igam)=flux_gam(igam)-Ferr_gam(igam)
            call fluxtofdens(slope_gam(igam),1.,100.,flux_gam(igam),1.,fdens,nudens)
            flux_gam(igam)=fdens
            frequency_gam(igam)=nudens
            call fluxtofdens(slope_gam(igam),1.,100.,FluxU_gam(igam),1.,fdens,nudens)
            FluxU_gam(igam)=fdens
            call fluxtofdens(slope_gam(igam),1.,100.,FluxL_gam(igam),1.,fdens,nudens)
            FluxL_gam(igam)=fdens
         endif
      ENDDO
99    continue
      close(lu_in)
      close(11)
c      write(*,*) i4p8,iuv,igam

      nrep(1:ixx)=0
      ixxss=0
      ixxrep=0
      do i=1,ixx
         if (i .ne. 1) then
            do j=1,i-1
               call DIST_SKY(ra_xx(i),dec_xx(i),ra_xx(j),dec_xx(j),dist)
               if (dist*3600. .lt. 15.) then
                  !write(*,*) 'nearby X-ray',ra_xx(i),dec_xx(i),xx_type(ixx)
                  ixxrep=ixxrep+1
                  nrep(i)=nrep(i)+1
                  xrayrepeat(nrep(i),i)=j
                  !track
                  goto 97
               endif
            enddo
         endif
         ixxss=ixxss+1
97    continue
      enddo
      !write(*,*) nrep(ixx),ixx
      !write(*,*) ixxss,ixxrep
      !write(*,*) xrayrepeat(1:nrep(ixx),ixx)

      open(12,file='Intermediate_out.txt',status='unknown',iostat=ier)
      ipass=0
      do i=1,icand
         ii1=0
         ii2=0
         if (i .le. irr) then
            do j=1,iuv
               call DIST_SKY(ra_rr(i),dec_rr(i),ra_uv(j),dec_uv(j),dist)
               if ( dist*3600. .le. poserr_rr(i)*1.3 ) then
                  if (flux_uv(j,1) .ne. 0.) then
                     aruv = 1.-log10(flux_rr(i)/flux_uv(j,1))/log10(frequency_rr(i)/frequency_uv(j,1))
                  else
                     aruv = 1.-log10(flux_rr(i)/flux_uv(j,2))/log10(frequency_rr(i)/frequency_uv(j,2))
                  endif
                  if (aruv .le. 0.75 ) then
                     ii1=ii1+1 !!!remove UV-r slope strange source 0.85
                     if (ii1 .eq. 1) write(*,'(a,i4,a)') "----------------------------------------"
                     if (ii1 .eq. 1) write(*,'(f9.5,2x,f9.5,a,f9.3,a)') ra_rr(i),dec_rr(i)," radio source ",
     &                 flux_rr(i)/frequency_rr(i)/1.E-26," mJy"
                     write(*,'("GALEX : ",2(f6.3,2x),10x,f7.3," arcsec away")') uvmag(j,1),uvmag(j,2),dist*3600.
                     write(*,'(6x,"radio-UV slope: ",f6.3)') aruv
                  endif
               endif
            enddo
            do j=1,i4p8
               call DIST_SKY(ra_rr(i),dec_rr(i),ra_4p8(j),dec_4p8(j),dist)
               if (dist*3600. .le. poserr_4p8(j)*1.3 ) then
                  alphar = 1.-log10(flux_rr(i)/flux_4p8(j))/log10(frequency_rr(i)/frequency_4p8(j))
                  if (alphar .le. 0.7 ) then
                     ii2=ii2+1 !!!remove radio extended sources
                     if ((ii2 .eq. 1) .and. (ii1 .eq. 0))
     &                   write(*,'(a,i4,a)') "----------------------------------------"
                     if ((ii2 .eq. 1) .and. (ii1 .eq. 0)) write(*,'(f9.5,2x,f9.5,a,f9.3,a)')
     &                  ra_rr(i),dec_rr(i)," radio source ",flux_rr(i)/frequency_rr(i)/1.E-26," mJy"
                     write(*,'(a,f9.3," mJy",10x,f7.3," arcsec away")')
     &                  type_4p8(j),flux_4p8(j)/flux2nufnu_4p8,dist*3600.
                     write(*,'("radio slope: ",f6.3)') alphar
                  endif
               endif
            enddo
            if (ii1+ii2 .gt. 0.) then
               ipass=ipass+1
               CALL RXgraphic_code(flux_rr(i)/frequency_rr(i)/1.E-26,'R',code)
               write (12,'(f9.5,2x,f9.5,2x,i6)') ra_rr(i),dec_rr(i),int(code)
               pass2(ipass)=i
            endif
         else if (i .gt. irr ) then
            do j=1,iuv
               call DIST_SKY(ra_xx(i-irr),dec_xx(i-irr),ra_uv(j),dec_uv(j),dist)
               if ((dist*3600. .le. poserr_xx(i-irr)*1.3 ) .and. (poserr_xx(i-irr) .le. 15.) ) then
                  if (flux_uv(j,1) .ne. 0.) then
                     auvx = 1.-log10(flux_uv(j,1)/flux_xx(i-irr))/log10(frequency_uv(j,1)/frequency_xx(i-irr))
                  else
                     auvx = 1.-log10(flux_uv(j,2)/flux_xx(i-irr))/log10(frequency_uv(j,2)/frequency_xx(i-irr))
                  endif
                  if (auvx .le. 1. ) then
                     ii1=ii1+1 !!!remove UV-x slope strange source 0.85
                     if (ii1 .eq. 1) write(*,'(a,i4,a)') "----------------------------------------"
                     if (ii1 .eq. 1) write(*,'(f9.5,2x,f9.5,a,es10.3)') ra_xx(i-irr),dec_xx(i-irr),
     &            " X-ray source with 1 keV flux ",flux_xx(i-irr)
                     write(*,'("GALEX : ",2(f6.3,2x),10x,f7.3," arcsec away")') uvmag(j,1),uvmag(j,2),dist*3600.
                     write(*,'(6x,"UV-X-ray slope: ",f6.3)') auvx
                  endif
                 !ra_uvmat(iuvmatch)=ra_uv(j)
                 !dec_uvmat(iuvmatch)=dec_uv(j)
               endif
            enddo
            if (ii1 .gt. 0.) then
               ipass=ipass+1
               CALL RXgraphic_code(flux_xx(i-irr),'X',code)
               write (12,'(f9.5,2x,f9.5,2x,i6)') ra_xx(i-irr),dec_xx(i-irr),int(code)
               pass2(ipass)=i
            endif
         endif
      enddo

      if ((ipass .eq. 0) .and. (isource .ne. 0)) then
         print *,achar(27),'[35;1m No candidates were found in intermediate phase',achar(27),'[0m'
         stop
      endif
      if (ipass+isource .eq. 0) then
         print *,achar(27),'[31;1m Unfortunatelly, no any candidates were found',achar(27),'[0m'
         stop
      endif

      do i=1,ipass
         k=pass2(i)
         if (i+isource .ne. 1) write(12,*) "===================="
         if (k .le. irr) then
            write(12,'(i4,2x,a,2(2x,f9.5),2x,a,2x,i2)') i+isource,"matched source",
     &         ra_rr(k),dec_rr(k),'source type',int(code/10000)
            write(12,'(4(es10.3,2x),2(f9.5,2x),f7.3,2x,i2)') frequency_rr(k),flux_rr(k),FluxU_rr(k),
     &          FluxL_rr(k),ra_rr(k),dec_rr(k),poserr_rr(k),rr_type(k)
         else
            write(12,'(i4,2x,a,2(2x,f9.5),2x,a,2x,i2)') i+isource,"matched source",
     &         ra_xx(k-irr),dec_xx(k-irr),'source type',int(code/10000)
            write(12,'(4(es10.3,2x),2(f9.5,2x),f7.3,2x,i2)') frequency_xx(k-irr),flux_xx(k-irr),
     &         FluxU_xx(k-irr),FluxL_xx(k-irr),ra_xx(k-irr),dec_xx(k-irr),poserr_xx(k-irr),xx_type(k-irr)
            do j=1,xpts(k-irr)
               write(12,'(4(es10.3,2x),i2)') frequency_xxot(j,k-irr),flux_xxot(j,k-irr),
     &            FluxU_xxot(j,k-irr),FluxL_xxot(j,k-irr),xxot_type(j,k-irr)
            enddo
         endif
      enddo
      write(12,*) ipass

      close(12)
      end

      SUBROUTINE DIST_SKY(alpha1,delta1,alpha2,delta2,dist)
      IMPLICIT NONE
      REAL*8 dist,alpha1,alpha2,delta1,delta2,costheta
      REAL*8 radian
      radian=57.2957795
      costheta=sin(delta1/radian)*sin(delta2/radian)+
     &         cos(delta1/radian)*cos(delta2/radian)*
     &         cos((alpha1-alpha2)/radian)
      dist=acos(costheta)*radian
      RETURN
      END

      SUBROUTINE fluxtofdens(gamma,bandl,bandu,flux,gev,fdens,nudens)
      real*4 alpha,bandu,bandl,flux,nudens,fdens,conval,kev,nuu,nul
      !write(*,*) alpha,flux,kev,bandu,bandl
      if (gamma .ne. 2. ) then
      conval=(1./(-gamma+1.))*((bandu)**(-gamma+1.)-(bandl)**(-gamma+1.))
      else
      conval=log(bandu/bandl)
      endif
      fdens=gev*(flux/conval)*((gev)**(-gamma))!!!!To photon flux at gev
      fdens=fdens*1.602E-19*1.E7*(gev*1.E9)
      nudens=(1.602E-19)*(gev*1.E9)/(6.626e-34)
      RETURN
      end

      SUBROUTINE RXgraphic_code(flux,RX,code)
      IMPLICIT none
      REAL*4 flux,code,rfl_max,rfl_min
      REAL*4 xfl_min,xfl_max
      INTEGER*4 radio_component,x_ray_component,source_type,temp
      CHARACTER*1 RX
      code = 0.
      rfl_min=0.8 ! 0.8 mJy
      rfl_max=8000. ! 8 Jy
      xfl_min = 1.e-16 ! 1.e-16 erg/cm2/s, nufnu
      xfl_max = 5.e-11
      radio_component = 0.
      x_ray_component = 0.
      IF (RX == 'R') THEN
      radio_component=int(alog10(flux/rfl_min)/alog10(rfl_max/rfl_min)*99.)
      IF (radio_component .GE. 99) THEN
      radio_component = 99
      ELSE IF (radio_component .LE. 1) THEN
      radio_component = 1
      ENDIF
      code = -90000.
      ELSE IF (RX == 'X') THEN
      IF (flux > xfl_min) THEN
      x_ray_component=int(alog10(flux/xfl_min)/alog10(xfl_max/xfl_min)*99.)
      ELSE
      x_ray_component = 1
      ENDIF
      IF (x_ray_component .GE. 99) THEN
      x_ray_component = 99
      ELSE IF (x_ray_component .Lt. 1) THEN
      x_ray_component = 1
      ENDIF
      code = -80000.
      ENDIF
      code = code -radio_component-100.*x_ray_component
      RETURN
      END

      SUBROUTINE mag2flux (nh,m_band,filter,flux,frequency)
c
c  converts u,v,i,h,b,r,j,k magnitudes into monochromatic fluxes
c  in units of erg/cm2/s for nufnu vs nu plots
c
      IMPLICIT none
      REAL*4 nh, flux , av , m_band, a_band, Rv
      REAL*4 c, lambda, const, frequency, a
      REAL*8 x,aa,bb,c1,c2,dx,px,ebv
      CHARACTER*3 filter
c        print *,' nh, m_band, filter ', nh, m_band,filter
c        call upc(filter)
      IF ((filter(1:3).NE.'fuv') .and. (filter(1:3).NE.'nuv')) THEN
         write (*,*) ' mag2flux: Filter not supported  '
         stop
      ENDIF
c extintion law taken from Cardelli et al. 1989 ApJ 345, 245
c in UV apply the UV relation from Fitzpatrick 1999
      Rv=3.1
      av = Rv*(-0.055+nh*1.987e-22) !!dust map from BH1978, assumed constant gas-to-dust ratio
      ebv=av/Rv
      if (av < 0.) av=0.
      if (filter(1:3) == 'fuv') then
         lambda=1528.
         const=log10(3631.)-23.
      else if (filter(1:3) == 'nuv') then
         lambda=2271.
         const=log10(3631.)-23.
      endif
c lambda from Amstrongs to microns
      x=10000./lambda
      if ((x .le. 1.1) .and. (x .ge. 0.3)) then
      a_band=(0.574*(x**1.61)-0.527*(x**1.61)/Rv)*av ! the a_lambda
      else if ((x .le. 3.3) .and. (x .ge. 1.1)) then
      x=x-1.82
      aa=1+(0.17699*x)-(0.50447*x**2)-(0.02427*x**3)+(0.73085*x**4)
     &     +(0.01979*x**5)-(0.77530*x**6)+(0.32999*x**7)
      bb=1.41338*x+(2.28305*x**2)+(1.07233*x**3)-(5.38434*x**4)
     &    -(0.662251*x**5)+(5.30260*x**6)-(2.09002*x**7)
      a_band=(aa+(bb/Rv))*av
      else if ((x .le. 10.) .and. (x .ge. 3.3)) then
      c2=-0.824+4.717/Rv
      c1=2.03-3.007*c2
      dx=(x*x)/((x**2-4.596**2)+(x*0.99)**2)
      px=0.5392*(x-5.9)**2+0.05644*(x-5.9)**2
      if (x .le. 5.9) px=0.
      a_band=(c1+c2*x+3.23*dx+0.41*px)*ebv+av
      endif
      c=2.9979e10
      a=1.0
      frequency=c/(lambda*1.e-8)
      flux = 10.**(-0.4*(m_band -a_band)+const)*frequency
      if (m_band .le. 0.) flux=0.
!m_band=0.
!lambda=0.
      RETURN
      END