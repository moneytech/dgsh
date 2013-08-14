#!/usr/local/bin/sgsh
#
# SYNOPSIS Nuclear magnetic resonance processing
# DESCRIPTION
# Nuclear magnetic resonance in-phase/anti-phase channel conversion and
# processing in heteronuclear single quantum coherence spectroscopy.
# Demonstrate processing of NMR data using the NMRPipe family of programs.
#
# See also F. Delaglio, S. Grzesiek, G. W. Vuister, G. Zhu, J. Pfeifer
# and A. Bax: NMRPipe: a multidimensional spectral processing system based
# on UNIX pipes. J. Biomol. NMR. 6, 277-293 (1995).
# http://spin.niddk.nih.gov/NMRPipe/
#

curl http://www.acornnmr.com/Data/ebc13.fid |
var2pipe -noaswap  \
  -xN              1280  -yN               400  \
  -xT               640  -yT               200  \
  -xMODE        Complex  -yMODE        Complex \
  -xSW        10002.501  -ySW         2800.000  \
  -xOBS         799.805  -yOBS          81.053  \
  -xCAR           4.754  -yCAR         118.618  \
  -xLAB              H1  -yLAB             N15  \
  -ndim               2  -aq2D          States \
  -verb |
scatter |{
	# IP/AP channel conversion
	# See http://tech.groups.yahoo.com/group/nmrpipe/message/389
	-| nmrPipe |
	   nmrPipe -fn SOL |
	   nmrPipe -fn SP -off 0.5 -end 0.98 -pow 2 -c 0.5 |
	   nmrPipe -fn ZF -auto |
	   nmrPipe -fn FT |
	   nmrPipe -fn PS -p0 177 -p1 0.0 -di |
	   nmrPipe -fn EXT -left -sw -verb |
	   nmrPipe -fn TP |
	   nmrPipe -fn COADD -cList 1 0 -time |
	   nmrPipe -fn SP -off 0.5 -end 0.98 -pow 1 -c 0.5 |
	   nmrPipe -fn ZF -auto |
	   nmrPipe -fn FT |
	   nmrPipe -fn PS -p0 0 -p1 0 -di |
	   nmrPipe -fn TP |
	   nmrPipe -fn POLY -auto -verb >A |.

	-| nmrPipe |
	   nmrPipe -fn SOL |
	   nmrPipe -fn SP -off 0.5 -end 0.98 -pow 2 -c 0.5 |
	   nmrPipe -fn ZF -auto |
	   nmrPipe -fn FT |
	   nmrPipe -fn PS -p0 177 -p1 0.0 -di |
	   nmrPipe -fn EXT -left -sw -verb |
	   nmrPipe -fn TP |
	   nmrPipe -fn COADD -cList 0 1 -time |
	   nmrPipe -fn SP -off 0.5 -end 0.98 -pow 1 -c 0.5 |
	   nmrPipe -fn ZF -auto |
	   nmrPipe -fn FT |
	   nmrPipe -fn PS -p0 -90 -p1 0 -di |
	   nmrPipe -fn TP |
	   nmrPipe -fn POLY -auto -verb >B |.

|} gather |{
	# We use temporary files rather than streams, because
	# addNMR mmaps its input files. The diagram displayed in the
	# example shows the notional data flow.
	addNMR -in1 A -in2 B -out A+B.sgsh.ft2 -c1 1.0 -c2 1.25 -add
	addNMR -in1 A -in2 B -out A-B.sgsh.ft2 -c1 1.0 -c2 1.25 -sub
|}
