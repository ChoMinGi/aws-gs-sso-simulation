# 위성 데이터 전송 시뮬레이션 (Satellite Downlink/Uplink Simulation)

이 레포지토리는 **MATLAB**의 `satelliteScenario`를 활용하여 X-band(다운링크)와 S-band(업링크)를 동시에 고려한 **위성-지상국 간 데이터 전송 시뮬레이션** 코드 예시입니다.


위성을 기준으로 AWS 의 GS 에서 지원하는 실제 지상국 여러 곳 중 **가장 높은 링크 용량**을 갖는 지상국을 골라 최대 성능으로 데이터를 다운링크한다는 시나리오를 시각화합니다.


(2023-02 부산대학교 조동현 교수님의 우주시스템공학 연구 프로젝트였습니다.)

---

## 주요 기능

1. **위성 궤도 설정**  
   - 준궤원, 경사 98도 등의 파라미터로 Sun-Synchronous Orbit 유사 환경 구성  
   - 24시간 동안 궤도를 추적하며 연결 가능 구간(interval)을 확인

2. **지상국 배치 & 안테나 설정**  
   - 11개 지상국(위경도) 정보를 토대로 `groundStation` 객체 생성  
   - S-band(업링크), X-band(다운링크)를 각각 송수신기(transmitter/receiver)로 세팅  
   - `link` 객체를 통해 각 지상국과 위성 간 연결 구간 계산

3. **데이터 전송 시뮬레이션**  
   - **다운링크 속도(50Mbps)** 를 예시로 삼아, 각 시간 스텝에서 가장 좋은 링크를 선택  
   - 전송된 데이터량, 남은 데이터량, 총 전송 시간을 누적 계산  
   - 지상국 스위칭 시에 별도의 연결 비용(딜레이)도 고려 가능

4. **시각화**  
   - **Link States**: 시간에 따른 각 지상국 링크 오픈/클로즈 상태  
   - **Link Capacity**: 시간축상 링크 용량 변화  
   - **Data Transferred**: 샘플링 타임 간격으로 전송된 비트량 그래프  

---

## 코드 구조

### 1) 핵심 스크립트
```plaintext
main_satellite_scenario.m (통합된 형태)
```
- **위성 시뮬레이션 객체** 생성  
- **위성 궤도 파라미터** 지정  
- **지상국 생성, 링크 세팅, 포인팅**  
- **데이터 전송 로직** (남은 데이터, 링크 용량 추적)  
- **결과 시각화** (그래프 3종 + 텍스트 출력)

### 2) 주요 변수 설명
- `startTime`, `stopTime`: 시뮬레이션 시작·종료 시간 (여기서는 2023-12-14 10:00 UTC ~ +24h)
- `sampleTime`: 시뮬레이션 샘플링 간격(초 단위)
- `sat1Tx`, `sat1Rx`: 위성의 X-band 송신기, S-band 수신기
- `gsTx`, `gsRx`: 각 지상국의 S-band 송신기, X-band 수신기
- `timeArray`, `numTimeSteps`: 시간 배열 및 타임스텝 개수
- `linkCapacities`, `linkStates`: [지상국 수, 시간 스텝 수] 형태로 각 지상국의 링크 상태/용량을 저장
- `remainingData`: 전송해야 하는 데이터의 남은 양 (초기 100MB)
- `usedGroundStations`: 실제로 전송에 사용된 지상국 인덱스 추적

---

## 실행 방법

1. **MATLAB 환경** 준비  
   - Satellite Toolbox (R2023a 이상 권장)
2. **스크립트 열기**  
   ```matlab
   % MATLAB 커맨드 윈도우에서
   main_satellite_scenario
   ```
   - 혹은 스크립트 이름을 직접 열어 실행(F5)
3. **시뮬레이션 결과 확인**  
   - 콘솔 출력:  
     - 전송 완료 시간 (초 단위)  
     - 사용된 지상국 순서  
     - 각 지상국별 통신 가능 시간대  
   - 그래프 3종:  
     1) 링크 상태(Heatmap)  
     2) 시간에 따른 링크 용량  
     3) 전송된 비트량(Bar Chart)

---

## 시뮬레이션 시나리오 개요

- **위성**  
  - Sun-Synchronous 궤도(고도 ~6900km, 경사각 98도)  
  - 24시간 동안 지상국과 접속 가능성 탐색
- **지상국**  
  - 서울, 싱가포르, 시드니 등 전 세계 11곳  
  - S-band(업) / X-band(다운) 설정, 접시 안테나(`gaussianAntenna`) 사용
- **데이터 전송**  
  - 100MB 정도의 파일을 50Mbps 다운링크로 전송한다 가정  
  - 샘플링 타임(10초)마다 가장 높은 링크 용량이 열려있는 지상국을 선택
- **추가 딜레이**  
  - 가령 스위칭 시점마다 20초 지연(connectionDelay) 고려

---

## 주요 결과

- **Total data transfer time**  
  - 24시간 이내에 전송 가능 여부 및 총 소요 시간  
- **Used Ground Station**  
  - 전송 과정에서 실제로 선택된 지상국 목록  
- **Link States & Capacities**  
  - 각 지상국이 특정 시간대에 어떤 링크 용량을 가지는지 2D 플롯

---

## 개선 / 확장 아이디어

1. **더 세밀한 SNR 모델**  
   - 지상국-위성 간 거리, 시선각, 기상 조건을 반영해 동적 SNR 계산  
2. **Orbit Propagator 고도화**  
   - 실제 TLE(orbital elements) 입력 후 정밀 궤도 예측  
3. **Switching 비용/전략**  
   - 단순 20초 고정이 아니라, 가령 각 지상국 별 위치·컴퓨팅 환경에 따라 스위칭 시간 상이하게 설정  
4. **업링크 속도 동적 활용**  
   - 업링크가 병목일 경우를 고려하여 Full-Duplex/ Half-Duplex 전송 모델링

---

## 라이센스 / 문의

- 본 예시 코드는 제한 없이 참고 용도로 사용해도 좋습니다.  
- 문의나 개선 제안은 Issue를 남겨주세요.

---

**요약**  
- `satelliteScenario` 객체로 24시간 시뮬레이션  
- X-band 다운링크(50Mbps), S-band 업링크(32kbps) 설정  
- 여러 지상국 중 **최적 링크**(가장 높은 용량)로 데이터 전송  
- 그래프·콘솔 로그를 통해 전송 현황을 직관적으로 파악 가능  
