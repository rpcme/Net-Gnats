
VERSION  = 0.07
RDIR     = releases
RELEASE  = Net-Gnats-${VERSION}
DIRNAME  = ${RDIR}/${RELEASE}
FILENAME = ${RELEASE}.tgz

release:
	if [ -d ${DIRNAME} ] ; then exit 1 ; fi
	if [ ! -d ${RDIR} ] ; then mkdir ${RDIR} ; fi
	cp -r Net ${DIRNAME}
	find ${DIRNAME} -name '*~' -print | xargs rm -rf
	find ${DIRNAME} -name 'CVS' -print | xargs rm -rf
	find ${DIRNAME} -name '*.sav' -print | xargs rm -rf
	cd releases ; tar -zcvf ${FILENAME} ${RELEASE}

ftp:
	@echo ftp upload.sourceforge.net
	@echo binary
	@echo put ${RDIR}/${FILENAME}
