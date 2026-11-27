// entry/src/main/ets/common/DeviceService.ets
import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';

export class DeviceStatus {
  temp: number = 24.0;
  humi: number = 50.0;
  gas: number = 1;
  human: number = 0;
  light: number = 0;
  motor: number = 0;
  gate: number = 0;
  beep: number = 0;
  mqttOnline: boolean = false;
  lastUpdated: number = 0;
}

class StatusApiResponse {
  code: number = 0;
  message: string = "";
  data?: DeviceStatus;
}

export class DeviceService {
  // 预置候选服务地址列表：
  // 1. 10.0.2.2:3000 (鸿蒙模拟器访问主机专用)
  // 2. 127.0.0.1:3000 (DevEco Studio 预览器 Previewer 访问本地)
  // 3. 10.84.189.134:3000 (局域网 WiFi / 鸿蒙真机访问电脑)
  private static candidateUrls: string[] = [
    "http://10.0.2.2:3000",
    "http://127.0.0.1:3000",
    "http://10.177.212.134:3000",
    "http://10.84.189.134:3000"
  ];
  private static activeBaseUrlIndex: number = 0;

  // 防抖限流控制：防止快速点击或滑块导致网络洪泛冲垮硬件
  private static lastSentCommand: string = "";
  private static lastSentTimestamp: number = 0;

  public static getBaseUrl(): string {
    return DeviceService.candidateUrls[DeviceService.activeBaseUrlIndex];
  }

  public static setBaseUrl(url: string): void {
    DeviceService.candidateUrls[0] = url;
    DeviceService.activeBaseUrlIndex = 0;
  }

  /**
   * 发送设备控制指令 (自带 300ms 智能防抖去重，保护硬件与网络)
   */
  public static control(command: string, callback?: (success: boolean) => void): void {
    let now = Date.now();
    if (command === DeviceService.lastSentCommand && (now - DeviceService.lastSentTimestamp < 350)) {
      console.log("【防抖拦截】过滤短时间内重复指令:", command);
      if (callback) callback(true);
      return;
    }
    DeviceService.lastSentCommand = command;
    DeviceService.lastSentTimestamp = now;

    let postData = JSON.stringify({ command: command, room_no: "8012" });
    DeviceService.sendRequestWithFallback("/api/device/control", http.RequestMethod.POST, postData, 0, (resString: string | null) => {
      if (resString) {
        if (callback) callback(true);
      } else {
        if (callback) callback(false);
      }
    });
  }

  /**
   * 获取设备与传感器实时状态 (包含实时温度、湿度、各设备状态)
   */
  public static getStatus(callback: (status: DeviceStatus | null) => void): void {
    DeviceService.sendRequestWithFallback("/api/device/status", http.RequestMethod.GET, "", 0, (resString: string | null) => {
      if (resString) {
        try {
          let res: StatusApiResponse = JSON.parse(resString) as StatusApiResponse;
          if (res.code === 200 && res.data) {
            callback(res.data);
            return;
          }
        } catch (e) {
          console.error("解析设备状态失败:", JSON.stringify(e));
        }
      }
      callback(null);
    });
  }

  /**
   * 自动多网段故障切换的网络请求辅助函数
   */
  private static sendRequestWithFallback(
    path: string,
    method: http.RequestMethod,
    extraData: string,
    urlIndex: number,
    finalCallback: (result: string | null) => void
  ): void {
    if (urlIndex >= DeviceService.candidateUrls.length) {
      finalCallback(null);
      return;
    }

    let baseUrl = DeviceService.candidateUrls[urlIndex];
    let fullUrl = `${baseUrl}${path}`;
    let httpRequest = http.createHttp();

    let requestOptions: http.HttpRequestOptions = {
      method: method,
      header: { 'Content-Type': 'application/json' },
      readTimeout: 2500,
      connectTimeout: 2500
    };
    if (method === http.RequestMethod.POST) {
      requestOptions.extraData = extraData;
    }

    httpRequest.request(fullUrl, requestOptions, (err: BusinessError, data: http.HttpResponse) => {
      httpRequest.destroy();
      if (!err && data && data.responseCode === 200) {
        DeviceService.activeBaseUrlIndex = urlIndex;
        finalCallback(data.result as string);
      } else {
        DeviceService.sendRequestWithFallback(path, method, extraData, urlIndex + 1, finalCallback);
      }
    });
  }

  public static showToast(msg: string): void {
    try {
      promptAction.showToast({ message: msg, duration: 1500 });
    } catch (e) {}
  }
}
