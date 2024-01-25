%{
Classes for extracting data from Thermo Element ICP Mass Spectrometer dat files
using matlab. This is a fork of the python code created by Dr. Philip Wenig and 
John H. Hartman
%}

%{
Copyright (c) 2014 Dr. Philip Wenig
Copyright (c) 2015-2020 John H. Hartman

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License version
2.1, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License version 2.1 along with this program.
If not, see <http://www.gnu.org/licenses/>.
%}

function Constants
	properties(Constant)	
		VERSION = '2.4'

		HDR_INDEX_OFFSET = 33
		HDR_INDEX_LEN = 39
		HDR_TIMESTAMP = 40

		SCAN_NUMBER = 9
		SCAN_DELTA = 7
		SCAN_ACF = 12
		SCAN_PREV_TIME = 18
		SCAN_TIME = 19
		SCAN_EDAC = 31
		SCAN_FCF = 34

		KEY_EOS = 0xF % end of scan/acquisition
		KEY_EOM = 0x8 % end of mass
		KEY_BSCAN = 0xC % B-scan
		KEY_B = 0xB % ??
		KEY_VOLT = 0x4 % accelerating voltage
		KEY_TIME = 0x3 % channel time
		KEY_MASS = 0x2 % magnet mass
		KEY_DATA = 0x1 % data

		DATA_ANALOG = 0x0
		DATA_PULSE = 0x1
		DATA_FARADAY = 0x8
	
end

function DATEception

end

function EOS

end

function NotOpen

end

function UnknownKey

end

function UnknownDataType

end

function Mass


end

function Scan


end

function ScanIterator

end

function DatFile
	properties

	end
	methods
		function obj = DatFile
	
	end


