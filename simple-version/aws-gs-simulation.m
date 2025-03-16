startTime = datetime(2023,12,14,10,0,0, 'TimeZone', 'UTC');
stopTime = startTime + days(1);


sampleTime = 10;
sc = satelliteScenario(startTime,stopTime,sampleTime);

% 위성 설정
semiMajorAxis = 6937800;  % meters
eccentricity = 0;
inclination = 98;  % degrees
rightAscensionOfAscendingNode = 0;  % degrees
argumentOfPeriapsis = 0;  % degrees
trueAnomaly = 0;  % degrees
sat1 = satellite(sc, semiMajorAxis, eccentricity, inclination, rightAscensionOfAscendingNode, argumentOfPeriapsis, trueAnomaly, "Name","Satellite 1", "OrbitPropagator","two-body-keplerian");

% 위성 안테나 설정
gimbalSat1Tx = gimbal(sat1, "MountingLocation",[0;0.65;0]);  % meters
gimbalSat1Rx = gimbal(sat1, "MountingLocation",[0;0.65;0]);  % meters

% X-band 송신기 설정 (다운링크)
sat1Tx = transmitter(gimbalSat1Tx, "MountingLocation",[0;0;1], "Frequency",8.4e9, "Power",15);  % X-band
gaussianAntenna(sat1Tx, "DishDiameter",0.5);  % meters

% S-band 수신기 설정 (업링크)
sat1Rx = receiver(gimbalSat1Rx, "MountingLocation",[0;0;1], "GainToNoiseTemperatureRatio",3, "RequiredEbNo",4);  % S-band
gaussianAntenna(sat1Rx, "DishDiameter",0.5);  % meters



% 지상국 및 안테나 설정
latitudeArray = [36.34067747841352, 1.4028769359084685, -33.85524717359871, 25.981592639066914, 59.283466555397354, 53.260911852630436, -33.73335591156351, -53.049329803156425, 40.154979129123156, 42.904057221696405, 20.061592874662367];
longitudeArray = [127.67264631378752, 103.78536794765901, 150.9492324832868, 50.54366610214531, 18.046524490493898, -8.980550859693631, 21.833498233274742, -70.97321826321934, -82.8813594444313, -121.15666991704295, -155.78910039092926];
gsNames = ["Seoul", "Singapore", "Sydney", "Bahrain", "Stockholm", "Ireland", "Cape Town", "Punta Arenas", "Ohio", "Oregon", "Hawaii"];

% 파일 크기 설정 (예: 10 MB)
fileSizeBits = 1000 * 1024 * 1024 * 8;  % 100 MB to bits

% 가정된 대역폭 (예: 50 MHz)
B = 50e6;  % Hz

% 시간 배열 생성
timeArray = startTime:seconds(sampleTime):stopTime;
numTimeSteps = length(timeArray);  % 추가된 부분


% 전체 데이터 전송 시간을 계산하기 위한 변수 초기화
totalDataTransferred = zeros(1, numTimeSteps);
totalTime = 0;

% 시간 배열 생성 (시간대 정보 없음)
timeArray = startTime:seconds(sampleTime):stopTime;

% 딜레이 설정 (예: 20초)
connectionDelay = 20;  % seconds

% 전송 시간과 딜레이를 고려한 전체 시간을 저장할 배열 초기화
totalTransferTimes = zeros(1, length(latitudeArray));

% 각 링크의 전송 용량 및 상태를 저장할 배열 초기화
linkCapacities = zeros(length(latitudeArray), numTimeSteps);
linkStates = zeros(length(latitudeArray), numTimeSteps);

% X-band 다운링크 및 S-band 업링크 속도 설정
downlink_speed = 50e6;  % X-band: 50 Mbit/s
uplink_speed = 32e3;   % S-band: 32 kbit/s

for i = 1:length(latitudeArray)
    gs = groundStation(sc, latitudeArray(i), longitudeArray(i), ...
        "Name", gsNames(i));
    
    gimbalGs = gimbal(gs, "MountingAngles",[0;180;0], ...
        "MountingLocation",[0;0;-5]);

    % S-band Transmitter 설정 (업링크)
    gsTx = transmitter(gimbalGs, "MountingLocation",[0;0;1], ...
        "Frequency",2.2e9, "Power",15);  % S-band
    gaussianAntenna(gsTx, "DishDiameter",2);  % meters

    gsRx = receiver(gimbalGs, "MountingLocation",[0;0;1], ...
        "GainToNoiseTemperatureRatio",3, "RequiredEbNo",1);  % decibels/Kelvin
    gaussianAntenna(gsRx, "DishDiameter",2);  % meters

    % 안테나 포인팅 설정
    pointAt(gimbalGs, sat1);
    pointAt(gimbalSat1Rx, gs);

    pointAt(gimbalSat1Tx,gs);
    pointAt(gimbalGs,sat1);
 
    % 링크 생성
    lnk = link(gsTx, sat1Rx, sat1Tx, gsRx);

    % 링크 인터벌 테이블 얻기
    intervals = linkIntervals(lnk);
    
    totalOpenTime = 0; % 총 열린 시간을 저장할 변수 초기화
    for j = 1:height(intervals)
        % StartTime과 EndTime이 이미 datetime 타입인지 확인
        % 이미 datetime 타입이라면, 시간대 정보만 설정
        openTime = intervals.StartTime(j);
        closeTime = intervals.EndTime(j);

        % 시간대를 UTC로 설정
        openTime.TimeZone = 'UTC';
        closeTime.TimeZone = 'UTC';

        % 인터벌의 시작과 종료 시간을 시간 배열의 인덱스로 변환
        openIdx = find(timeArray >= openTime, 1, 'first');
        closeIdx = find(timeArray <= closeTime, 1, 'last');

        % 링크 상태 배열 업데이트
        linkStates(i, openIdx:closeIdx) = 1;

        % 해당 인터벌 동안의 링크 용량 계산 (다운링크 및 업링크 속도 사용)
        linkCapacities(i, openIdx:closeIdx) = downlink_speed;  % 예시로 다운링크 속도 사용
    end
end

% 전송할 데이터의 양 설정
remainingData = fileSizeBits;

% 사용된 지상국의 인덱스를 저장할 배열 초기화
usedGroundStations = [];

% 마지막으로 사용된 지상국을 추적하기 위한 변수 초기화
lastUsedStation = -1;

% 각 시간 단계에서 최적의 링크 선택 및 데이터 전송
for t = 1:numTimeSteps
    if remainingData > 0
        % 해당 시간에서 가능한 링크 중 가장 높은 용량을 가진 링크 선택
        availableLinks = find(linkStates(:, t) == 1);
        if ~isempty(availableLinks)
            [~, bestLinkIdx] = max(linkCapacities(availableLinks, t));
            bestLink = availableLinks(bestLinkIdx);

            % 선택된 링크를 통해 전송 가능한 데이터 양 계산
            dataTransferred = min(linkCapacities(bestLink, t) * sampleTime, remainingData);

            % 전송된 데이터 양과 남은 데이터 양 업데이트
            totalDataTransferred(t) = dataTransferred;
            remainingData = remainingData - dataTransferred;

            % 전송 시간 업데이트
            totalTime = totalTime + sampleTime;

            % 이전에 사용된 지상국과 다른 경우에만 사용된 지상국 인덱스 추가
            if bestLink ~= lastUsedStation
                usedGroundStations = [usedGroundStations, bestLink];
                lastUsedStation = bestLink;
            end
        else
            % 사용 가능한 링크가 없으면 시간만 증가
            totalTime = totalTime + sampleTime;
        end
    else
        break; % 모든 데이터 전송 완료
    end
end

% 사용된 지상국 순서 출력
for idx = usedGroundStations
    fprintf('Used Ground Station: %s\n', gsNames(idx));
end



% 전체 전송 시간 출력
fprintf('Total data transfer completed in %f seconds.\n', totalTime);

% 링크 상태 시각화
figure;
imagesc(datetime(timeArray), 1:length(latitudeArray), linkStates);
xlabel('Time');
ylabel('Link Number');
title('Link States (Open/Closed)');
colorbar;
datetick('x', 'keeplimits'); % x축을 날짜 형식으로 변환

% 링크 용량 시각화
figure;
plot(timeArray, linkCapacities');
xlabel('Time');
ylabel('Link Capacity (bps)');
title('Link Capacities Over Time');
legend(gsNames, 'Location', 'eastoutside');

% 데이터 전송량 시각화
figure;
bar(timeArray, totalDataTransferred);
xlabel('Time');
ylabel('Data Transferred (bits)');
title('Data Transferred Over Time');

% 사용된 지상국 순서 출력
for idx = usedGroundStations
    fprintf('Used Ground Station: %s\n', gsNames(idx));
end

% 각 지상국의 통신 시간 출력
for i = 1:length(latitudeArray)
    fprintf('Ground Station: %s\n', gsNames(i));
    intervals = linkIntervals(link(gsTx, sat1Rx, sat1Tx, receiver(gimbal(groundStation(sc, latitudeArray(i), longitudeArray(i)), "MountingAngles",[0;180;0], "MountingLocation",[0;0;-5]))));
    for j = 1:height(intervals)
        openTime = intervals.StartTime(j);
        closeTime = intervals.EndTime(j);

        % datetime 객체를 사용하여 출력 형식 지정
        fprintf('    Open Time: %s, Close Time: %s\n', ...
            openTime.Format('uuuu-MM-dd HH:mm:ss'), ...
            closeTime.Format('uuuu-MM-dd HH:mm:ss'));
    end
end
