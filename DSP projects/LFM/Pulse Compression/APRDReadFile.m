function [hdrData, metaData, sweepData] = APRDReadFile(fn, recStart, numRecs)
% Read set of sweeps from .IMB Akela binary file (also position metadata).
%
% Returns sweep data and
% metadata, including onboard sensor position and encoder information.
%
% INPUT
%       fn  -  path to .IMB file
%       recStart  - record within file to begin reading in data; we do not
%          know a prior numrecords
%       numRecs   - total number to read in
%
%       Note: Takes 54 sec to read in 1024 records
%
% OUTPUT
%      hdrData - an Akela struct with data file header info with members:
%   sensor: [1x9 struct]
%           encoder: [1x1 struct]
%           version: 21
%          revision: 5
%         buildDate: '10/30/2012'
%       nDataPoints: 2501
%         startFreq: 500
%          stopFreq: 3000
%        sampleRate: 30000
%     antennaSwitch: 'OFF'
%       alternateTX: 'OFF'
%       alternateRX: 'OFF'
%     alternateTXRX: 'ON'
%       nullingPath: '.imb'
%     enableNulling: 'OFF'
%        useEncoder: 'OFF'
%            useGPS: 'OFF'
%      useTelemetry: 'ON'
%
%  meta      - an Akela struct with per-record values for rx, tx,
%              sensor position info, etc
%     nC
%     frameNumber
%     sweepNumber
%     timeStamp
%     TX
%     RX
%     TXPort         <<< NOTE: port1=H, port2=V polaraization
%     RXPort
%     gain
%     GPS
%     GPS_heading
%     GPS_bestposheader
%     GPS_bestpos
%     GPS_bestutmheader
%     GPS_bestutm
%     telemetry
%     nS
%     stitch
%     ititch
%     parameter
%     data
%
%  sweepData     - [nSweeps x nFreqs] complex array of sweep data
%
%
% % HEK added gui to select file; and return value;
% HEK return metadata and entire image instead of last scan
% Note:
% 
% ProcessParameters
% 
% {
% 
% 	enableGateValues ON
% 
% 	gateTx1 268.555
% 
% 	gateTx1Rx1 24.4141
% 
% 	gateRx1 286.865
% 
% 	gateRx1Rx2 0
% 
% 	gateRx2 0
% 
% 	gateRx2Tx1 18.3106
% 
% }
    
    if nargin<1;
        [fn, pn] = uigetfile({'*.imb', '*.ins'},'Select IMB file to open');
    else
        [path, name, ext] = fileparts(fn);
        pn = path;
        fn = [name ext];
    end
        
    if nargin<2;
        answer = inputdlg({'Start Record','End Record (-1 for all)'},...
            'Enter desired records from file', 1, {'1','-1'});
        recStart = str2num(answer{1});
        numRecs   = str2num(answer{2});
    end
    if numRecs == -1; numRecs = 9999999999; end;
    
    % fid = APRDFileOpen('ExampleFile.imb');
    assert(exist([pn filesep fn])==2, ['Cannot stat ' pn filesep fn]);
    
    fid = APRDFileOpen([pn filesep fn]);
    fprintf(1,'FileByte: %d \n', ftell(fid));
    
    % Positions file ready to read first scan.
    hdrData = APRDReadConfig(fid);  % Appears to be 2622 Bytes
    
    if ~APRDHasData(fid);
        disp 'FILE HAS NO MORE DATA';
        hdrData.FILE_DONE=true;
        fclose(fid);
        return;
    else
        hdrData.FILE_DONE=false;
    end;
    
    display(hdrData.sensor);
    
    recNum = 0; % Actual read-in record counter
    
    hdrSize = ftell(fid);
    
    % Prealloc will help!
    sweepData = zeros(numRecs, hdrData.nDataPoints);
    
    % Read in one record to get the size, then seek to desired record
    S = APRDReadScan(fid, hdrData.version); % Each rec contains 20365
    recSize = ftell(fid)-hdrSize; %20365
    
    % Seek to start of desired record
    bytesToSkip = hdrSize + recSize*(recStart);
    status = fseek(fid, bytesToSkip, 'bof');
    assert(status==0, 'Unable to seek into file');
    
    fprintf(1, 'Seeking into IMB file to read record %d...\n', recStart);
    while recNum < numRecs && APRDHasData(fid)
        
        recNum = recNum+1;
        S      = APRDReadScan(fid, hdrData.version); % Each rec contains 20369
        metaData(recNum) = S;  
        sweepData(recNum,:) = S.data;
       
        % Display progress
        skip = round(numRecs/10);
        if mod(recNum, skip)==0;
            fprintf(1, 'Record %d (of %d) - Frame:%d Sweep:%d TX:%d RX:%d Time:%g \n',...%GPS: %g %g  TELE %g %g\n',...
                recNum, numRecs, S.frameNumber, S.sweepNumber, S.TX, S.RX, S.timeStamp)%,..
        end;
        
    end
    
    S=rmfield(S,'data')  ;  % Superceded by concatenated array of sweepData
    fclose(fid);
    %    plot(20 * log10(abs(S.data)));
end


%%
function [fid] = APRDFileOpen(filename)
    fid = fopen(filename, 'r');
end

%%
function [C] = APRDReadConfig(fid)
    C.sensor = []; C.encoder = [];
    while ~feof(fid)
        line = fgets(fid);
        if strncmp(line, 'EOH', 3)
            break;
        else
            C = parseLine(C, line);
            fprintf(1, '%s', line);
        end
    end
end

%%
function [B] = APRDHasData(fid)
    [nC, B] = fread(fid, 1, '*uint32');
    fseek(fid, -4, 0);
end

%%
function [S] = APRDReadScan(fid, version)
    S.nC = fread(fid, 1, '*uint32');
    %
    S = readScanHeader(fid, S);
    % GPS Data
    if version > 15
        S = readGPS(fid, S);
   end
    % Telemetry Data
    S = readTelemetry(fid, S);
    % Stitch Points
    S = readStitchPoints(fid, S);
    % data
    S = readScaparameterata(fid, S);
end

%%
function [S] = readScanHeader(fid, S)
    S.frameNumber = fread(fid, 1, '*uint32');
    S.sweepNumber = fread(fid, 1, '*uint32');
    S.timeStamp = fread(fid, 1, '*double');
    S.TX = fread(fid, 1, '*uint32');
    S.RX = fread(fid, 1, '*uint32');
    S.TXPort = fread(fid, 1, '*uint32');
    S.RXPort = fread(fid, 1, '*uint32');
    S.gain = fread(fid, 1, '*uint32');
end

%%
function [S] = readScaparameterata(fid, S)
    S.parameter = fread(fid, 1, '*uint32');
    S.data = zeros(1, S.parameter);

    % for i = 1:S.parameter
    %     im = fread(fid, 1, '*float');
    %     re = fread(fid, 1, '*float');
    %
    %     S.data(i) = complex(re, im);
    % end

    % Faster way to read data (single call to fread)
    dat = fread(fid,2*S.parameter,'*float');
    S.data = complex(dat(2:2:end),dat(1:2:(end-1)));
end

%%
function [S] = readStitchPoints(fid, S)
    S.nS = fread(fid, 1, '*uint');

    S.stitch = zeros(1,S.nS);
    S.ititch = zeros(1,S.nS);

    for i = 1:S.nS
        im = fread(fid, 1, '*float');
        re = fread(fid, 1, '*float');
        istitch = fread(fid, 1, '*uint32');

        S.stitch(i) = complex(re, im);
        S.istitch(i) = istitch;
    end
end

%% These functions require 16 bit alignment.
function [S] = readGPS(fid, S)
    S.GPS.isactive = fread(fid, 1, '*uint8');
	if S.GPS.isactive
        S = readGPS_heading(fid, S);
		S = readGPS_bestposheader(fid, S);
		S = readGPS_bestpos(fid, S);
		S = readGPS_bestutmheader(fid, S);
		S = readGPS_bestutm(fid, S);
    end
end

%%
function [S] = readGPS_heading(fid, S)
	S.GPS_heading.heading = fread(fid, 1, '*double');
	S.GPS_heading.isDegrees = fread(fid, 1, '*uint8'); fread(fid, 7, '*uint8'); % alignment
end

%%
function [S] = readGPS_bestposheader(fid, S)
	S.GPS_bestposheader.headerLength = fread(fid, 1, '*uint8'); fread(fid, 1, '*uint8');
	S.GPS_bestposheader.messageID = fread(fid, 1, '*uint16');
	S.GPS_bestposheader.messageType = fread(fid, 1, '*uint8');
	S.GPS_bestposheader.portAddress = fread(fid, 1, '*uint8');
	S.GPS_bestposheader.messageLength = fread(fid, 1, '*uint16');
	S.GPS_bestposheader.messageSequence = fread(fid, 1, '*uint16');
	S.GPS_bestposheader.idleTime = fread(fid, 1, '*uint8');
	S.GPS_bestposheader.timeStatus = fread(fid, 1, '*uint8');
	S.GPS_bestposheader.GPSWeek = fread(fid, 1, '*uint16'); fread(fid, 2, '*uint8');
	S.GPS_bestposheader.GPSMilliSec = fread(fid, 1, '*uint32');
	S.GPS_bestposheader.receiverStatus = fread(fid, 1, '*uint32');
	S.GPS_bestposheader.reserved = fread(fid, 1, '*uint16');
	S.GPS_bestposheader.versionSW = fread(fid, 1, '*uint16');
end

%%
function [S] = readGPS_bestpos(fid, S)
	S.GPS_bestpos.solutionStatus = fread(fid, 1, '*uint32');
	S.GPS_bestpos.solutionType = fread(fid, 1, '*uint32');
	S.GPS_bestpos.latitude = fread(fid, 1, '*double');
	S.GPS_bestpos.longitude = fread(fid, 1, '*double');
	S.GPS_bestpos.height = fread(fid, 1, '*double');
	S.GPS_bestpos.uparameterulation = fread(fid, 1, '*float');
	S.GPS_bestpos.datumID = fread(fid, 1, '*uint32');
	S.GPS_bestpos.latitudeSTD = fread(fid, 1, '*float');
	S.GPS_bestpos.longitudeSTD = fread(fid, 1, '*float');
	S.GPS_bestpos.heightSTD = fread(fid, 1, '*float');
	S.GPS_bestpos.baseStationID = fread(fid, 1, '*uint32');
	S.GPS_bestpos.differentialAge = fread(fid, 1, '*float');
	S.GPS_bestpos.solutionAge = fread(fid, 1, '*float');
	S.GPS_bestpos.nSatsTracked = fread(fid, 1, '*uint8');
	S.GPS_bestpos.nSatsUsed = fread(fid, 1, '*uint8');
	S.GPS_bestpos.ggL1 = fread(fid, 1, '*uint8');
	S.GPS_bestpos.ggL1L2 = fread(fid, 1, '*uint8');
	S.GPS_bestpos.reserved1 = fread(fid, 1, '*uint8');
	S.GPS_bestpos.solutionStatusEx = fread(fid, 1, '*uint8');
	S.GPS_bestpos.reserved2 = fread(fid, 1, '*uint8');
	S.GPS_bestpos.sigMask = fread(fid, 1, '*uint8');
	S.GPS_bestpos.CRC = fread(fid, 1, '*uint32'); fread(fid, 4, '*uint8');
end

%%
function [S] = readGPS_bestutmheader(fid, S)
	S.GPS_bestutmheader.headerLength = fread(fid, 1, '*uint8'); fread(fid, 1, '*uint8');
	S.GPS_bestutmheader.messageID = fread(fid, 1, '*uint16');
	S.GPS_bestutmheader.messageType = fread(fid, 1, '*uint8');
	S.GPS_bestutmheader.portAddress = fread(fid, 1, '*uint8');
	S.GPS_bestutmheader.messageLength = fread(fid, 1, '*uint16');
	S.GPS_bestutmheader.messageSequence = fread(fid, 1, '*uint16');
	S.GPS_bestutmheader.idleTime = fread(fid, 1, '*uint8');
	S.GPS_bestutmheader.timeStatus = fread(fid, 1, '*uint8');
	S.GPS_bestutmheader.GPSWeek = fread(fid, 1, '*uint16'); fread(fid, 2, '*uint8');
	S.GPS_bestutmheader.GPSMilliSec = fread(fid, 1, '*uint32');
	S.GPS_bestutmheader.receiverStatus = fread(fid, 1, '*uint32');
	S.GPS_bestutmheader.reserved = fread(fid, 1, '*uint16');
	S.GPS_bestutmheader.versionSW = fread(fid, 1, '*uint16');
    
    
end

%%
function [S] = readGPS_bestutm(fid, S)
	S.GPS_bestutm.solutionStatus = fread(fid, 1, '*uint32');
	S.GPS_bestutm.positionType = fread(fid, 1, '*uint32');
	S.GPS_bestutm.zoneNo = fread(fid, 1, '*uint32');
	S.GPS_bestutm.zoneLetter = fread(fid, 1, '*uint32');
	S.GPS_bestutm.northing = fread(fid, 1, '*double');
	S.GPS_bestutm.easting = fread(fid, 1, '*double');
	S.GPS_bestutm.height = fread(fid, 1, '*double');
	S.GPS_bestutm.uparameterulation = fread(fid, 1, '*float');
	S.GPS_bestutm.datumID = fread(fid, 1, '*uint32');
	S.GPS_bestutm.northingSTD = fread(fid, 1, '*float');
	S.GPS_bestutm.eastingSTD = fread(fid, 1, '*float');
	S.GPS_bestutm.heightSTD = fread(fid, 1, '*float');
	S.GPS_bestutm.baseStationID = fread(fid, 1, '*uint32');
	S.GPS_bestutm.differentialAge = fread(fid, 1, '*float');
	S.GPS_bestutm.solutionAge = fread(fid, 1, '*float');
	S.GPS_bestutm.nSatsTracked = fread(fid, 1, '*uint8');
	S.GPS_bestutm.nSatsUsed = fread(fid, 1, '*uint8');
	S.GPS_bestutm.ggL1 = fread(fid, 1, '*uint8');
	S.GPS_bestutm.ggL1L2 = fread(fid, 1, '*uint8');
	S.GPS_bestutm.reserved1 = fread(fid, 1, '*uint8');
	S.GPS_bestutm.solutionStatusEx = fread(fid, 1, '*uint8');
	S.GPS_bestutm.reserved2 = fread(fid, 1, '*uint8');
	S.GPS_bestutm.sigMask = fread(fid, 1, '*uint8');
	eS.GPS_bestutm.CRC = fread(fid, 1, '*uint32'); fread(fid, 4, '*uint8');
end

%%
function [S] = readTelemetry(fid, S)
    S.telemetry.sweepDelay = fread(fid, 1, '*double');
    % odometer data...
    S.telemetry.x = fread(fid, 1, '*double');
    S.telemetry.y = fread(fid, 1, '*double');
    S.telemetry.distance = fread(fid, 1, '*double');
    S.telemetry.theta = fread(fid, 1, '*float');
    S.telemetry.velocity = fread(fid, 1, '*float');
    S.telemetry.turnRate = fread(fid, 1, '*float'); fread(fid, 4, '*uint8');
    S.telemetry.timeStamp = fread(fid, 1, '*double');
    % encoder data...
    S.telemetry.LSE = fread(fid, 1, '*uint32');
    S.telemetry.RSE = fread(fid, 1, '*uint32');
    S.telemetry.flipperSE = fread(fid, 1, '*uint32'); fread(fid, 4, '*uint8');
end

%% Makes sure that the comparison is uniquely on the first valid element in s.
function [B] = compare(s, k)
    s = textscan(s, '%s');
    if size(s{1},1) == 0 
        B = 0;
    else
        B = strcmp(s{1}(1), k);
    end
end

%%
function [C] = parseLine(C, line)
    %%
    if compare(line, 'version')
       C.version = sscanf(line, '%*s %f');
    end
    if compare(line, 'revision')
      C.revision = sscanf(line, '%*s %f');
    end
    if compare(line, 'buildDate')
      C.buildDate = sscanf(line, '%*s %s');
    end
    if compare(line, 'timeSync')
      C.timeSync = sscanf(line, '%*s %f');
    end
    %%
    if compare(line, 'nDataPoints')
      C.nDataPoints = sscanf(line, '%*s %d');
    end
    if compare(line, 'startFreq')
      C.startFreq = sscanf(line, '%*s %f');
    end
    if compare(line, 'stopFreq')
      C.stopFreq = sscanf(line, '%*s %f');
    end
    if compare(line, 'sampleRate')
      C.sampleRate = sscanf(line, '%*s %d');
    end
    %%
    if compare(line, 'antennaSwitch')
      C.antennaSwitch = sscanf(line, '%*s %s');
    end
    if compare(line, 'alternateTX')
      C.alternateTX = sscanf(line, '%*s %s');
    end
    if compare(line, 'alternateRX')
      C.alternateRX = sscanf(line, '%*s %s');
    end
    if compare(line, 'alternateTXRX')
      C.alternateTXRX = sscanf(line, '%*s %s');
    end
    if compare(line, 'nullingPath')
      C.nullingPath = sscanf(line, '%*s %s');
    end
    if compare(line, 'enableNulling')
      C.enableNulling = sscanf(line, '%*s %s');
    end
    if compare(line, 'Sensor')
      C.sensor = [C.sensor parseSensor(line)];
    end
    %%
    if compare(line, 'useEncoder')
      C.useEncoder = sscanf(line, '%*s %s');
    end
    if compare(line, 'useGPS')
      C.useGPS = sscanf(line, '%*s %s');
    end
    if compare(line, 'useTelemetry')
      C.useTelemetry = sscanf(line, '%*s %s');
    end
    if compare(line, 'Encoder')
      C.encoder = [C.encoder parseEncoder(line)];
    end
end

%% Header En IP cRev cShaft wBase wCirc Type X Y
%% Encoder ON 192.168.1.201 100 65535 1.83 2.82 TRACK_YX 0 0 1
function [E] = parseEncoder(line)
    E = []; s = textscan(line, '%s'); s = s{:};
    E.enable = s{2};
    E.ip = s{3};
    E.crev = str2double(s{4});
    E.cshaft = str2double(s{5});
    E.wbase = str2double(s{6});
    E.wcirc = str2double(s{7});
    E.type = s{8};
    E.x = str2double(s{9});
    E.y = str2double(s{10}); 
end
    
%% Header ENABLE ID PORT IP GAIN NULLING_K NULLING_THETA TX_PORT RX_PORT TX_DELAY RX_DELAY TX RX MONO X Y Z TYPE
%% Sensor YES ? PORT1 192.168.1.200 0 0 0 0 0 0 0 NO NO NO 0 0 0 ARRAY_MASTER
function [S] = parseSensor(line)
    S = []; s = textscan(line, '%s'); s = s{:};
    S.enable = s{2};
    S.id = s{3};
    S.port = s{4};
    S.ip = s{5};
    S.gain = str2double(s{6});
    S.nulling_k = str2double(s{7});
    S.nulling_theta = str2double(s{8});
    S.tx_port = cast(s{9}, 'uint8');
    S.rx_port = cast(s{10}, 'uint8');
    S.tx_delay = str2double(s{11});
    S.rx_delay = str2double(s{12});
    S.tx = s{13};
    S.rx = s{14};
    S.mono = s{15};
    S.x = str2double(s{16});
    S.y = str2double(s{17});
    S.z = str2double(s{18});
    S.type = s{19};
end






%     n = 9891840;
%     frewiparameter(fid); fseek(fid, n, 0)
%     
%     while ~feof(fid)
%         c = fread(fid, 1, '*uint8');
%         fprintf(1, '%u %x\n', n, c);
%         n = n + 1;
%     end
