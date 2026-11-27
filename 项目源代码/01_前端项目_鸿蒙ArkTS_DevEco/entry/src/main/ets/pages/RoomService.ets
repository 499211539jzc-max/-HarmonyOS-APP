// entry/src/main/ets/pages/RoomService.ets
// 专属客房服务页面
import router from '@ohos.router';

// ==========================================
// 1. 数据模型定义
// ==========================================
interface ServiceItem {
  id: number;
  name: string;
  icon: string;
  route: string;
  badge?: string;
}

@Entry
@Component
struct ExclusiveRoomService {
  // ==========================================
  // 3. 状态变量
  // ==========================================
  @State selectedDevice: string = '空调';
  @State problemDesc: string = '';
  @State isSubmitEnabled: boolean = false;

  // ==========================================
  // 4. 页面构建
  // ==========================================
  build() {
    Scroll() {
      Column() {
        this.HeaderSection()
        this.ServiceGridSection()
        this.RepairFormSection()
        this.OrderTrackingSection()
      }
      .width('100%')
      .backgroundColor('#F5F7F9')
      .padding({ bottom: 20 })
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
  }

  // ==========================================
  // 5. 各模块 UI
  // ==========================================

  /**
   * 顶部头部区域
   */
  @Builder HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 返回按钮
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .onClick(() => {
              router.back()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ bottom: 10 })

        // 标题
        Column({ space: 5 }) {
          Text('您的专属客房服务')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('随时为您安排')
            .fontSize(14)
            .fontColor(Color.White)
            .opacity(0.9)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .padding({ left: 20, top: 50, right: 20 })
      .width('100%')
    }
    .width('100%')
    .height(180)
    .backgroundColor('#009688')
  }

  /**
   * 核心服务网格区域
   */
  @Builder ServiceGridSection() {
    Column() {
      Text('核心服务区')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 20, bottom: 15 })
        .width('100%')

      Grid() {
        ForEach(this.getServiceData(), (item: ServiceItem) => {
          GridItem() {
            Column({ space: 8 }) {
              Stack({ alignContent: Alignment.TopEnd }) {
                // 用 emoji 作为图标
                Text(item.icon)
                  .fontSize(28)
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)

                if (item.badge) {
                  Text(item.badge)
                    .fontSize(10)
                    .fontColor(Color.White)
                    .backgroundColor(Color.Red)
                    .width(16)
                    .height(16)
                    .textAlign(TextAlign.Center)
                    .borderRadius(8)
                    .offset({ x: 5, y: -5 })
                }
              }

              Text(item.name)
                .fontSize(12)
                .fontColor('#666666')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              console.info(`跳转到: ${item.route}`)
              AlertDialog.show({
                title: item.name,
                message: `${item.name}功能开发中，敬请期待！`,
                confirm: {
                  value: "确定",
                  action: () => {}
                }
              })
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .rowsGap(20)
      .width('100%')
      .height(160)
    }
    .padding({ left: 20, right: 20 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: -30 })
    .shadow({ radius: 10, color: '#1A000000', offsetX: 0, offsetY: 2 })
  }

  /**
   * 故障报修表单区域
   */
  @Builder RepairFormSection() {
    Column() {
      Row() {
        Text('故障报修')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('开启')
          .fontSize(14)
          .fontColor('#009688')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 20 })

      // 设备类型
      Column({ space: 8 }) {
        Text('设备类型:')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Row() {
          Text(this.selectedDevice)
            .fontSize(14)
            .fontColor('#333333')
          Blank()
          Text('∨')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .padding({ top: 12, bottom: 12, left: 10, right: 10 })
        .backgroundColor('#F5F7F9')
        .borderRadius(8)
        .onClick(() => {
          AlertDialog.show({
            title: "选择设备类型",
            message: "请选择故障设备",
            buttons: [
              { value: "空调", action: () => { this.selectedDevice = "空调" } },
              { value: "热水器", action: () => { this.selectedDevice = "热水器" } },
              { value: "电视", action: () => { this.selectedDevice = "电视" } },
              { value: "灯光", action: () => { this.selectedDevice = "灯光" } },
            ]
          })
        })
      }
      .margin({ bottom: 16 })

      // 问题描述
      Column({ space: 8 }) {
        Text('问题描述:')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        TextArea({ placeholder: '制冷效果较弱，出风口有异响', text: this.problemDesc })
          .width('100%')
          .height(80)
          .backgroundColor('#F5F7F9')
          .borderRadius(8)
          .onChange((value: string) => {
            this.problemDesc = value;
            this.isSubmitEnabled = value.length > 0;
          })
      }
      .margin({ bottom: 16 })

      // 上传框
      Row({ space: 15 }) {
        this.UploadBox()
        this.UploadBox()
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 提交按钮
      Button('提交报修')
        .width('100%')
        .height(45)
        .backgroundColor(this.isSubmitEnabled ? '#009688' : '#CCCCCC')
        .fontColor(Color.White)
        .fontSize(16)
        .borderRadius(22.5)
        .onClick(() => {
          if (this.isSubmitEnabled) {
            AlertDialog.show({
              title: "提交成功",
              message: "报修信息已提交，工作人员将尽快处理！",
              confirm: {
                value: "确定",
                action: () => {
                  this.problemDesc = ''
                  this.isSubmitEnabled = false
                }
              }
            })
          }
        })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 16 })
  }

  /**
   * 上传图片方框
   */
  @Builder UploadBox() {
    Column() {
      Text('+')
        .fontSize(30)
        .fontColor('#999999')
        .margin({ bottom: 5 })
      Text('拍照/上传')
        .fontSize(10)
        .fontColor('#999999')
    }
    .width(80)
    .height(80)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F7F9')
    .borderRadius(8)
    .border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed })
    .onClick(() => {
      console.info('点击上传图片')
    })
  }

  /**
   * 底部进度追踪
   */
  @Builder OrderTrackingSection() {
    Column() {
      Row() {
        Text('订单进度追踪')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('📍')
          .fontSize(16)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 20 })

      Row() {
        this.TimelineItem('14:00', '提交保洁', true)
        Divider().color('#009688').strokeWidth(2).width(40).margin({ bottom: 20 })
        this.TimelineItem('14:05', '服务员已接单', true)
        Divider().color('#E0E0E0').strokeWidth(2).width(40).margin({ bottom: 20 })
        this.TimelineItem('14:12', '正在前往', false)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Top)
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 16 })
  }

  /**
   * 时间轴节点
   */
  @Builder TimelineItem(time: string, label: string, isActive: boolean) {
    Column({ space: 5 }) {
      Text(time)
        .fontSize(12)
        .fontColor(isActive ? '#333333' : '#999999')
        .fontWeight(isActive ? FontWeight.Medium : FontWeight.Normal)

      Circle()
        .width(10)
        .height(10)
        .fill(isActive ? '#009688' : '#E0E0E0')

      Text(label)
        .fontSize(12)
        .fontColor(isActive ? '#333333' : '#999999')
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  // ==========================================
  // 6. 数据辅助函数
  // ==========================================
  getServiceData(): ServiceItem[] {
    return [
      { id: 1, name: '保洁申请', icon: '🧹', route: 'pages/CleaningRequest' },
      { id: 2, name: '请勿打扰', icon: '🚫', route: 'pages/DoNotDisturb' },
      { id: 3, name: '故障报修', icon: '🔧', route: 'pages/RepairRequest', badge: '1' },
      { id: 4, name: '续房申请', icon: '📅', route: 'pages/ExtendStay' },
      { id: 5, name: '退房申请', icon: '🚪', route: 'pages/CheckOut' },
      { id: 6, name: '呼叫前台', icon: '📞', route: 'pages/CallFrontDesk' },
    ];
  }
}
