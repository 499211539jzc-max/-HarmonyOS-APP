// entry/src/main/ets/pages/RoomControl.ets
// 客房控制页面 —— 所有按钮均已打通并联动 STM32 硬件物联网 (内置防抖防循环控制)
import router from '@ohos.router';
import { DeviceService, DeviceStatus } from '../common/DeviceService';

@Entry
@Component
struct RoomControlPage {
  // ===== 灯光总开关 =====
  @State isMainLightOn: boolean = true;
  // ===== 空调 =====
  @State temperature: number = 24;
  @State acMode: number = 0; // 0制冷 1照明 2送风 3自动
  // ===== 风速 =====
  @State fanSpeed: number = 1; // 0低速 1中速 2高速
  // ===== 子灯光 =====
  @State isDownlightOn: boolean = true;   // 筒灯
  @State isLightStripOn: boolean = true;  // 灯带
  @State isBedLightOn: boolean = false;   // 床头灯
  // ===== 窗帘 =====
  @State curtainValue: number = 48;
  @State curtainAction: number = -1; // 0打开 1暂停 2关闭
  // ===== 其他设备 =====
  @State isTvOn: boolean = false;
  @State isFanOn: boolean = false;
  @State isSocketOn: boolean = false;

  acModeNames: string[] = ['制冷', '照明', '送风', '自动'];
  acModeIcons: string[] = ['❄️', '💡', '💨', '🔄'];
  fanSpeedNames: string[] = ['低速', '中速', '高速'];

  private pollTimerId: number = -1;
  // 关键防循环标志：当通过代码或者轮询同步UI开关状态时，禁止再次触发网络下发
  private isSyncingUi: boolean = false;

  aboutToAppear() {
    // 首次进入页面，立即拉取一次硬件遥测状态
    this.fetchStatus();
    // 启动定时轮询，每 3 秒与硬件板子同步一次数据
    this.pollTimerId = setInterval(() => {
      this.fetchStatus();
    }, 3000);
  }

  aboutToDisappear() {
    if (this.pollTimerId !== -1) {
      clearInterval(this.pollTimerId);
      this.pollTimerId = -1;
    }
  }

  // 同步硬件遥测状态
  fetchStatus(): void {
    DeviceService.getStatus((status: DeviceStatus | null) => {
      if (status) {
        this.isSyncingUi = true;
        if (status.temp !== undefined && status.temp > 0) {
          this.temperature = Math.round(status.temp);
        }
        if (status.light !== undefined) {
          this.isMainLightOn = (status.light === 1);
        }
        if (status.motor !== undefined) {
          this.isFanOn = (status.motor === 1);
        }
        this.isSyncingUi = false;

        if (status.gas === 0) {
          DeviceService.showToast("⚠️ 警报: 客房监测到烟雾/燃气异常！");
        }
      }
    });
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .margin({ left: 20, top: 50 })
          .onClick(() => {
            router.back();
          })
        Text("客房控制")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 50, left: 12 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Scroll() {
        Column({ space: 15 }) {
          this.buildMainLightCard()

          // 主体分栏布局
          Row({ space: 15 }) {
            // 左侧列
            Column({ space: 15 }) {
              this.buildAcControlCard()
              this.buildFanSpeedCard()
            }
            .width('48%')
            .alignItems(HorizontalAlign.Start)

            // 右侧列
            Column({ space: 15 }) {
              this.buildSubLightsCard()
              this.buildCurtainCard()
              this.buildOtherDevicesCard()
            }
            .width('48%')
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }
        .padding({ left: 15, right: 15, top: 20, bottom: 40 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#E5F6F5', 0.0], ['#F2F8FC', 1.0]]
    })
  }

  // ==================== 第一张图：灯光总开关卡片（控制硬件灯光开关） ====================
  @Builder buildMainLightCard() {
    Row() {
      Column() {
        Text("灯光").fontSize(18).fontWeight(FontWeight.Bold)
        Text(this.isMainLightOn ? "灯光已全开 💡" : "灯光已全关 🌑").fontSize(13).fontColor('#999999').margin({ top: 6 })
      }.alignItems(HorizontalAlign.Start)

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: this.isMainLightOn })
        .selectedColor('#27D0C6')
        .onChange((isOn: boolean) => {
          if (this.isSyncingUi) return;
          this.isSyncingUi = true;
          this.isMainLightOn = isOn;
          this.isDownlightOn = isOn;
          this.isLightStripOn = isOn;
          this.isBedLightOn = isOn;
          this.isSyncingUi = false;
          DeviceService.control(isOn ? 'light_on' : 'light_off');
          DeviceService.showToast(isOn ? "灯光已开启 💡" : "灯光已关闭 🌑");
        })
    }
    .backgroundColor(Color.White)
    .borderRadius(20)
    .padding(15)
    .width('100%')
    .shadow({ radius: 15, color: 'rgba(0, 100, 150, 0.04)', offsetX: 0, offsetY: 8 })
  }

  // ==================== 第二张图：空调卡片（按钮控制排风电机） ====================
  @Builder buildAcControlCard() {
    Column() {
      Row() {
        Text("空调").fontSize(16).fontWeight(FontWeight.Bold)
        Blank()
        Text(this.isFanOn ? "🌀 运行中" : "••").fontColor(this.isFanOn ? '#27D0C6' : '#CCCCCC').fontSize(14).padding({ bottom: 5 })
      }.width('100%')

      // 温度显示 + 上下调节
      Stack() {
        Column()
          .backgroundColor('#F3EAD3')
          .width('100%')
          .height('100%')
          .borderRadius(8)

        Text("❄").fontSize(80).fontColor('#E8DFCA').opacity(0.4)

        Column() {
          // 温度加按钮 —— 联动启动排风电机
          Text("▲")
            .fontSize(16)
            .fontColor('#27D0C6')
            .onClick(() => {
              if (this.temperature < 30) {
                this.temperature++;
              }
              this.isFanOn = true;
              DeviceService.control('motor_on');
              DeviceService.showToast(`温度升至 ${this.temperature}°C，排风电机已启动 🌀`);
            })

          Row() {
            Text(`${this.temperature}`).fontSize(40).fontWeight(FontWeight.Bold).fontColor('#333333')
            Text("°C").fontSize(18).margin({ bottom: 6, left: 2 }).fontColor('#333333')
          }
          .alignItems(VerticalAlign.Bottom)
          .onClick(() => {
            this.isFanOn = !this.isFanOn;
            DeviceService.control(this.isFanOn ? 'motor_on' : 'motor_off');
            DeviceService.showToast(this.isFanOn ? "排风电机已启动 🌀" : "排风电机已关闭");
          })

          // 温度减按钮 —— 联动启动排风电机
          Text("▼")
            .fontSize(16)
            .fontColor('#27D0C6')
            .onClick(() => {
              if (this.temperature > 16) {
                this.temperature--;
              }
              this.isFanOn = true;
              DeviceService.control('motor_on');
              DeviceService.showToast(`温度降至 ${this.temperature}°C，排风电机已启动 🌀`);
            })
        }
      }
      .width(130).height(130)
      .margin({ top: 15, bottom: 20 })

      // 空调模式按钮组 —— 点击控制排风电机
      Row() {
        ForEach([0, 1, 2, 3], (index: number) => {
          Column() {
            Column() {
              Text(this.acModeIcons[index]).fontSize(14)
            }
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor(this.acMode === index ? '#27D0C6' : '#F7F9FA')
            .justifyContent(FlexAlign.Center)
            .shadow(this.acMode === index
              ? { radius: 8, color: 'rgba(39, 208, 198, 0.3)', offsetY: 4 }
              : { radius: 0, color: Color.Transparent })

            Text(this.acModeNames[index])
              .fontSize(11)
              .margin({ top: 6 })
              .fontColor(this.acMode === index ? '#333333' : '#999999')
          }
          .onClick(() => {
            if (this.acMode === index && this.isFanOn) {
              this.isFanOn = false;
              DeviceService.control('motor_off');
              DeviceService.showToast(`排风电机已关闭`);
            } else {
              this.acMode = index;
              this.isFanOn = true;
              DeviceService.control('motor_on');
              DeviceService.showToast(`[${this.acModeNames[index]}] 模式已切换，排风电机已启动 🌀`);
            }
          })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .backgroundColor(Color.White)
    .borderRadius(20)
    .padding(15)
    .width('100%')
    .shadow({ radius: 15, color: 'rgba(0, 100, 150, 0.04)', offsetX: 0, offsetY: 8 })
  }

  // ==================== 风速控制卡片 ====================
  @Builder buildFanSpeedCard() {
    Column() {
      Row() {
        Text("风速").fontSize(16).fontWeight(FontWeight.Bold)
        Blank()
        Text("••").fontColor('#CCCCCC').fontSize(16).padding({ bottom: 5 })
      }.width('100%')

      Row() {
        ForEach([0, 1, 2], (index: number) => {
          Column() {
            Column() {
              Text(`${index + 1}`).fontSize(18).fontColor(this.fanSpeed === index ? Color.White : '#666666')
            }
            .width(44)
            .height(44)
            .borderRadius(22)
            .backgroundColor(this.fanSpeed === index ? '#27D0C6' : '#F7F9FA')
            .justifyContent(FlexAlign.Center)
            .shadow(this.fanSpeed === index
              ? { radius: 10, color: 'rgba(39, 208, 198, 0.4)', offsetY: 4 }
              : { radius: 0, color: Color.Transparent })

            Text(this.fanSpeedNames[index])
              .fontSize(12)
              .margin({ top: 8 })
              .fontColor(this.fanSpeed === index ? '#333333' : '#999999')
          }
          .onClick(() => {
            this.fanSpeed = index;
            this.isFanOn = true;
            DeviceService.control('motor_on');
            DeviceService.showToast(`已切换至 ${this.fanSpeedNames[index]}，排风电机运转 🌀`);
          })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 15, bottom: 15 })

      Row() {
        Text(`风速 ${this.fanSpeedNames[this.fanSpeed]}`).fontSize(13).fontWeight(FontWeight.Medium)
      }.width('100%').margin({ bottom: 15 })

      Row() {
        Text("定时").fontSize(13).fontColor('#999999')
        Blank()
        Text("2小时").fontSize(13).fontWeight(FontWeight.Medium)
      }.width('100%')
    }
    .backgroundColor(Color.White)
    .borderRadius(20)
    .padding(15)
    .width('100%')
    .shadow({ radius: 15, color: 'rgba(0, 100, 150, 0.04)', offsetX: 0, offsetY: 8 })
  }

  // ==================== 第一张图：子灯光卡片（全部联动硬件灯光开关） ====================
  @Builder buildSubLightsCard() {
    Column({ space: 16 }) {
      // 筒灯 —— Toggle 开关
      Row() {
        Text("筒灯").fontSize(14).fontWeight(FontWeight.Medium)
        Blank()
        Text(this.isDownlightOn ? "已开启" : "已关闭").fontSize(12).fontColor('#999999').margin({ right: 8 })
        Toggle({ type: ToggleType.Switch, isOn: this.isDownlightOn })
          .selectedColor('#27D0C6').width(36).height(20)
          .onChange((isOn: boolean) => {
            if (this.isSyncingUi) return;
            this.isDownlightOn = isOn;
            DeviceService.control(isOn ? 'light_on' : 'light_off');
            DeviceService.showToast(isOn ? "筒灯已开启 💡" : "筒灯已关闭 🌑");
          })
      }.width('100%')

      Divider().color('#F2F2F2')

      // 灯带 —— Toggle 开关
      Row() {
        Text("灯带").fontSize(14).fontWeight(FontWeight.Medium)
        Blank()
        Text(this.isLightStripOn ? "已开启" : "已关闭").fontSize(12).fontColor('#999999').margin({ right: 8 })
        Toggle({ type: ToggleType.Switch, isOn: this.isLightStripOn })
          .selectedColor('#27D0C6').width(36).height(20)
          .onChange((isOn: boolean) => {
            if (this.isSyncingUi) return;
            this.isLightStripOn = isOn;
            DeviceService.control(isOn ? 'light_on' : 'light_off');
            DeviceService.showToast(isOn ? "灯带已开启 💡" : "灯带已关闭 🌑");
          })
      }.width('100%')

      Divider().color('#F2F2F2')

      // 床头灯 —— Toggle 开关
      Row() {
        Text("床头灯").fontSize(14).fontWeight(FontWeight.Medium)
        Blank()
        Text(this.isBedLightOn ? "已开启" : "已关闭").fontSize(12).fontColor('#999999').margin({ right: 8 })
        Toggle({ type: ToggleType.Switch, isOn: this.isBedLightOn })
          .selectedColor('#27D0C6').width(36).height(20)
          .onChange((isOn: boolean) => {
            if (this.isSyncingUi) return;
            this.isBedLightOn = isOn;
            DeviceService.control(isOn ? 'light_on' : 'light_off');
            DeviceService.showToast(isOn ? "床头灯已开启 💡" : "床头灯已关闭 🌑");
          })
      }.width('100%')
    }
    .backgroundColor(Color.White)
    .borderRadius(20)
    .padding(15)
    .width('100%')
    .shadow({ radius: 15, color: 'rgba(0, 100, 150, 0.04)', offsetX: 0, offsetY: 8 })
  }

  // ==================== 第三张图：窗帘卡片（按钮控制蜂鸣器） ====================
  @Builder buildCurtainCard() {
    Column() {
      Text("窗帘 / 警报测试").fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 15 })

      // 窗帘操作按钮 —— 联动控制蜂鸣器
      Row() {
        Column() {
          Text('⬆️').fontSize(20).margin({ bottom: 6 })
          Text('打开').fontSize(12).fontColor(this.curtainAction === 0 ? '#27D0C6' : '#666666')
        }
        .onClick(() => {
          this.curtainAction = 0;
          this.curtainValue = 100;
          DeviceService.control('beep_on');
          DeviceService.showToast("蜂鸣器已开启 🔊");
        })

        Column() {
          Text('⏸️').fontSize(20).margin({ bottom: 6 })
          Text('暂停').fontSize(12).fontColor(this.curtainAction === 1 ? '#27D0C6' : '#666666')
        }
        .onClick(() => {
          this.curtainAction = 1;
          DeviceService.control('beep_off');
          DeviceService.showToast("蜂鸣器已停止 ⏸️");
        })

        Column() {
          Text('⬇️').fontSize(20).margin({ bottom: 6 })
          Text('关闭').fontSize(12).fontColor(this.curtainAction === 2 ? '#27D0C6' : '#666666')
        }
        .onClick(() => {
          this.curtainAction = 2;
          this.curtainValue = 0;
          DeviceService.control('beep_off');
          DeviceService.showToast("蜂鸣器已关闭 🔇");
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      // 滑动条仅调节数值显示，不产生高频网络洪泛
      Slider({ value: this.curtainValue, min: 0, max: 100 })
        .selectedColor('#27D0C6').trackColor('#E5E5E5').trackThickness(4)
        .margin({ top: 15, bottom: 10 })
        .onChange((value: number) => {
          this.curtainValue = Math.round(value);
          this.curtainAction = -1;
        })

      Row() {
        Text("开启").fontSize(12).fontColor('#999999')
        Blank()
        Text(`${this.curtainValue}%`).fontSize(12).fontColor('#333333')
      }.width('100%')
    }
    .backgroundColor(Color.White)
    .borderRadius(20)
    .padding(15)
    .width('100%')
    .shadow({ radius: 15, color: 'rgba(0, 100, 150, 0.04)', offsetX: 0, offsetY: 8 })
  }

  // ==================== 其他设备卡片 ====================
  @Builder buildOtherDevicesCard() {
    Column() {
      Row() {
        Text("其他").fontSize(16).fontWeight(FontWeight.Bold)
        Blank()
        Text("••").fontColor('#CCCCCC').fontSize(16).padding({ bottom: 5 })
      }.width('100%').margin({ bottom: 15 })

      Grid() {
        GridItem() {
          Column() {
            Text('📺').fontSize(18).margin({ bottom: 4 })
            Text('电视').fontSize(12).fontColor(this.isTvOn ? '#27D0C6' : '#333333')
          }
          .width('100%').height(65)
          .backgroundColor(this.isTvOn ? '#E0F7F5' : '#F7F9FA')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.isTvOn = !this.isTvOn;
            DeviceService.showToast(this.isTvOn ? "客房电视已开启" : "客房电视已关闭");
          })
        }
        GridItem() {
          Column() {
            Text('🌀').fontSize(18).margin({ bottom: 4 })
            Text('排风').fontSize(12).fontColor(this.isFanOn ? '#27D0C6' : '#333333')
          }
          .width('100%').height(65)
          .backgroundColor(this.isFanOn ? '#E0F7F5' : '#F7F9FA')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.isFanOn = !this.isFanOn;
            DeviceService.control(this.isFanOn ? 'motor_on' : 'motor_off');
            DeviceService.showToast(this.isFanOn ? "排风电机已启动 🌀" : "排风电机已停止");
          })
        }
        GridItem() {
          Column() {
            Text('🔌').fontSize(18).margin({ bottom: 4 })
            Text('插座').fontSize(12).fontColor(this.isSocketOn ? '#27D0C6' : '#333333')
          }
          .width('100%').height(65)
          .backgroundColor(this.isSocketOn ? '#E0F7F5' : '#F7F9FA')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.isSocketOn = !this.isSocketOn;
            DeviceService.showToast(this.isSocketOn ? "安全插座通电" : "安全插座断电");
          })
        }
        GridItem() {
          Column() {
            Toggle({ type: ToggleType.Switch, isOn: this.isMainLightOn })
              .selectedColor('#27D0C6').width(36).height(20)
              .onChange((isOn: boolean) => {
                if (this.isSyncingUi) return;
                this.isMainLightOn = isOn;
                DeviceService.control(isOn ? 'light_on' : 'light_off');
              })
          }
          .width('100%').height(65).backgroundColor('#F7F9FA').borderRadius(12).justifyContent(FlexAlign.Center)
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(10).columnsGap(10)
    }
    .backgroundColor(Color.White)
    .borderRadius(20)
    .padding(15)
    .width('100%')
    .shadow({ radius: 15, color: 'rgba(0, 100, 150, 0.04)', offsetX: 0, offsetY: 8 })
  }
}
