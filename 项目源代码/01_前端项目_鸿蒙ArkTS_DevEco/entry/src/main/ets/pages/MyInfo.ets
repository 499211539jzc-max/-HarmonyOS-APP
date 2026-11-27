// entry/src/main/ets/pages/MyInfo.ets
// 我的信息页面
import router from '@ohos.router';

@Entry
@Component
struct MyInfoPage {
  // 弹窗控制状态
  @State showCheckInDialog: boolean = false
  // 推送通知开关
  @State pushOn: boolean = true
  //前台电话
  @State helpPhone: boolean = false
  @State showDialing: boolean = false
  //酒店介绍
  //历史报修弹窗
  @State showRepairPopup: boolean = false
  //保洁记录弹窗
  @State showCleanPopup: boolean = false
  @State showHotelPopup: boolean = false
  // 清除缓存相关状态
  @State showCacheProgress: boolean = false
  @State cacheProgressValue: number = 0
  // 定时器变量
  cacheTimer: number | null = null

  aboutToDisappear() {
    // 页面销毁时清除定时器，防止内存泄漏
    if (this.cacheTimer !== null) {
      clearInterval(this.cacheTimer)
    }
  }

  // 清除缓存进度逻辑
  startClearCache() {
    this.showCacheProgress = true
    this.cacheProgressValue = 0
    if (this.cacheTimer !== null) {
      clearInterval(this.cacheTimer)
    }
    // 5秒完成进度，每200ms更新一次
    this.cacheTimer = setInterval(() => {
      this.cacheProgressValue += 4
      if (this.cacheProgressValue >= 100) {
        this.cacheProgressValue = 100
        clearInterval(this.cacheTimer!)
        // 进度满100后延迟1秒关闭弹窗
        setTimeout(() => {
          this.showCacheProgress = false
        }, 1000)
      }
    }, 200)
  }

  build() {
    Stack() {
      Scroll() {

        Column() {
          Row() {
            Image($r("sys.media.ohos_ic_public_arrow_left"))
              .width(28)
              .height(28)
              .onClick(() => {
                //返回上一页
                router.back()
              })
            Blank()
          }
          .width('100%')
          .padding({ left: 16, top: 16, right: 16 })
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [[0x005799, 0.0], [0x009699, 1]]
          })

          // ========== 顶部渐变头部 ==========
          // 顶部渐变头部区域
          Column() {
            // ========== 这里就是头像位置 ==========
            Image($r("app.media.avatar"))
              .width(100)
              .height(100)
              .borderRadius(50)
              .border({ width: 4, color: 0XFFFFFFFF })
            // ======================================

            Text("张先生")
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(0XFFFFFFFF)
              .margin({ top: 8 })

            Text("铂金会员")
              .fontSize(16)
              .fontColor(0x926B00)
              .backgroundColor(0xF9DD88)
              .padding({
                left: 16,
                right: 16,
                top: 4,
                bottom: 4
              })
              .borderRadius(20)
              .margin({ top: 6 })

          }
          .width('100%')
          .padding({ bottom: 40 })
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [[0x005799, 0.0], [0x009699, 1]]
          })

          // ========== 数据卡片：累计入住/积分/优惠券 ==========
          Row() {
            Column() {
              Text("累计入住").fontSize(16).fontColor("#666")
              Row() {
                Text("18").fontSize(28).fontWeight(FontWeight.Bold)
                Text("天").fontSize(14).fontWeight(FontWeight.Normal)
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text("我的积分").fontSize(16).fontColor("#666")
              Text("2680").fontSize(28).fontWeight(FontWeight.Bold)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text("优惠券").fontSize(16).fontColor("#666")
              Row() {
                Text("4").fontSize(28).fontWeight(FontWeight.Bold)
                Text("张").fontSize(14).fontWeight(FontWeight.Normal)
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('92%')
          .padding(24)
          .backgroundColor("#fff9e8")
          .borderRadius(16)
          .margin({ top: -32 })

          // ========== 菜单模块1 ==========
          //入住信息
          Column() {
            //
            Row() {
              Row() {
                Image($r("app.media.hotel_current_Check_in_Info")).width(28).height(28).fillColor("#0d9488")
                Text("当前入住信息").fontSize(20).margin({ left: 8 })
                Blank()
              }
              .layoutWeight(1)

            }
            .width('100%')
            .padding(20)


            //
            Row() {
              Column() {
                Image($r("app.media.hotel_hotel_intro")).width(28).height(28).fillColor("#666")
                Text("酒店介绍").fontSize(18).margin({ top: 8 })
              }
              .layoutWeight(1)
              .padding(16)
              .alignItems(HorizontalAlign.Center)

              .onClick(() => {
                this.showHotelPopup = true; // 点击打开弹窗
              })

              Column() {
                Image($r("app.media.hotel_cleaning_records")).width(28).height(28).fillColor("#666")
                Text("前台电话").fontSize(18).margin({ top: 8 })
              }
              .layoutWeight(1)
              .padding(16)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.helpPhone = true;
              })

              Column() {
                Image($r("app.media.hotel_order_details")).width(28).height(28).fillColor("#666")
                Text("订单详情").fontSize(18).margin({ top: 8 })
              }
              .layoutWeight(1)
              .padding(16)
              .alignItems(HorizontalAlign.Center)

              .onClick(() => {
                this.showCheckInDialog = true
              })
            }
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ top: 20 })

          // ========== 菜单模块2 我的服务记录 ==========
          //我的服务记录
          Column() {
            Row() {
              Row() {
                Image($r("app.media.hotel_my_service_records")).width(28).height(28).fillColor("#666")
                Text("我的服务记录").fontSize(20).margin({ left: 8 })
              }
              .layoutWeight(1)

            }
            .width('100%')
            .padding(20)

            Row() {
              Column() {
                Image($r("app.media.hotel_maintence_history")).width(28).height(28).fillColor("#ef4444")
                Text("历史报修").fontSize(18).margin({ top: 8 })
              }
              .layoutWeight(1)
              .padding(16)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.showRepairPopup = true; // 点击打开弹窗
              })

              Column() {
                Image($r("app.media.hotel_cleaning_records")).width(28).height(28).fillColor("#999")
                Text("保洁记录").fontSize(18).margin({ top: 8 })
              }
              .layoutWeight(1)
              .padding(16)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.showCleanPopup = true; // 点击打开弹窗
              })
            }
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ top: 20 })

          // ========== 软件设置 ==========
          Column() {
            Row() {
              Image($r("app.media.hotel_app_settings")).width(28).height(28).fillColor("#999")
              Text("软件设置").fontSize(20)

            }
            .width('100%')
            .padding(20)

            // 新增：推送通知，右侧开关
            Row() {
              Text("推送通知").fontSize(20)
              Toggle({ type: ToggleType.Switch, isOn: this.pushOn })
                .onChange((val: boolean) => {
                  this.pushOn = val
                })
            }
            .width('100%')
            .padding(20)
            .justifyContent(FlexAlign.SpaceBetween)

            // 新增：清除缓存，点击触发进度条弹窗
            Row() {
              Text("清除缓存").fontSize(20)
              Image($r("app.media.hotel_clear_cache")).width(24).height(24).fillColor("#999")
            }
            .width('100%')
            .padding(20)
            .onClick(() => {
              this.startClearCache()
            })

            Row() {
              Text("修改密码").fontSize(20)
              Image($r("app.media.hotel_change_password")).width(24).height(24).fillColor("#999")
            }
            .width('100%')
            .padding(20)

            Button("退出登录 / 解除房间绑定")
              .width("92%")
              .height(60)
              .fontSize(20)
              .fontColor(Color.White)
              .backgroundColor(0xffe62e2e)
              .borderRadius(30)
              .margin({ top: 40, bottom: 40 })
              .onClick(() => {
                // 退出登录，回到登录页
                router.clear()
                router.replaceUrl({ url: 'pages/Index' })
              })
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ top: 20, bottom: 40 })

        }
        .width('100%')

      }
      .width('100%')
      .height('100%')

      // ========== 酒店介绍 ==========
      if (this.showHotelPopup) {
        Column() {
          Column() {
            Text("酒店信息").fontSize(24).fontWeight(FontWeight.Bold).margin({ bottom: 15 })
            Text("酒店名称：星光酒店").fontSize(18).margin({ bottom: 8 })
            Text("酒店地址：南昌市红谷滩新区").fontSize(18).margin({ bottom: 8 })
            Text("联系电话：0791-88888888").fontSize(18).margin({ bottom: 20 })

            Button("关闭")
              .onClick(() => {
                this.showHotelPopup = false;
              })
          }
          .padding(24)
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#00000060")
        .justifyContent(FlexAlign.Center)
      }

      //酒店前台A界面
      if (this.helpPhone) {
        Column() {
          Column() {
            Text("前台联系电话")
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })
            Text("0791-88888888")
              .fontSize(20)
              .margin({ bottom: 24 })
            Button("拨打")
              .width('100%')
              .height(44)
              .onClick(() => {
                this.helpPhone = false; //关闭当前弹窗
                this.showDialing = true; //打开拨号弹窗
              })
            Button("关闭")
              .width('100%')
              .height(44)
              .margin({ top: 24 })
              .onClick(() => {
                this.helpPhone = false
              })
          }
          .padding(24)
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#00000060")
        .justifyContent(FlexAlign.Center)
      }

      //酒店前台B界面
      if (this.showDialing) {
        Column() {
          Column() {
            Text("正在为您拨打号码")
              .fontSize(20)
              .margin({ bottom: 24 })
            Button("取消")
              .width('100%')
              .height(44)
              .onClick(() => {
                this.showDialing = false;
              })
          }
          .padding(24)
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#00000060")
        .justifyContent(FlexAlign.Center)
      }

      // ========== 悬浮弹窗：当前入住信息 ==========
      if (this.showCheckInDialog) {
        Column() {
          Column() {
            Text("订单信息")
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })

            Text("酒店名称：城市精品酒店")
              .fontSize(18)
              .margin({ top: 6 })
            Text("房间号：806")
              .fontSize(18)
              .margin({ top: 6 })
            Text("入住时间：2026-09-12")
              .fontSize(18)
              .margin({ top: 6 })
            Text("离店时间：2026-10-7")
              .fontSize(18)
              .margin({ top: 6 })
            Text("房型：豪华大床房")
              .fontSize(18)
              .margin({ top: 6 })

            Button("关闭")
              .width('100%')
              .height(44)
              .margin({ top: 24 })
              .onClick(() => {
                this.showCheckInDialog = false
              })
          }
          .padding(24)
          .width('82%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#00000060")
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showCheckInDialog = false
        })
      }

      // ========== 历史报修弹窗 ==========
      if (this.showRepairPopup) {
        Column() {
          Column() {
            Text("历史报修")
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })
            Text("报修时间：2026-08-12")
              .fontSize(18)
              .margin({ top: 6 })
            Text("房间号：806")
              .fontSize(18)
              .margin({ top: 6 })
            Text("报修内容：卫生间水龙头漏水")
              .fontSize(18)
              .margin({ top: 6 })
            Text("处理状态：已完成维修")
              .fontSize(18)
              .margin({ top: 6 })
            Button("关闭")
              .width('100%')
              .height(44)
              .margin({ top: 24 })
              .onClick(() => {
                this.showRepairPopup = false;
              })
          }
          .padding(24)
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#00000060")
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showRepairPopup = false
        })
      }

      // ========== 保洁记录弹窗 ==========
      if (this.showCleanPopup) {
        Column() {
          Column() {
            Text("近期保洁记录")
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })
            Text("保洁时间：2026-09-30 上午9:30")
              .fontSize(18)
              .margin({ top: 6 })
            Text("房间号：806")
              .fontSize(18)
              .margin({ top: 6 })
            Text("保洁内容：全屋打扫、更换布草")
              .fontSize(18)
              .margin({ top: 6 })
            Text("保洁人员：李阿姨")
              .fontSize(18)
              .margin({ top: 6 })
            Button("关闭")
              .width('100%')
              .height(44)
              .margin({ top: 24 })
              .onClick(() => {
                this.showCleanPopup = false;
              })
          }
          .padding(24)
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#00000060")
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showCleanPopup = false
        })
      }

      // ========== 清除缓存进度弹窗 ==========
      if (this.showCacheProgress) {
        Column() {
          Column() {
            Progress({ value: this.cacheProgressValue, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(6)
            Text("缓存清理中请稍后...")
              .fontSize(18)
              .margin({ top: 16 })
          }
          .padding(24)
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#00000060")
        .justifyContent(FlexAlign.Center)
      }

    }
    .width('100%')
    .height('100%')
  }
}
