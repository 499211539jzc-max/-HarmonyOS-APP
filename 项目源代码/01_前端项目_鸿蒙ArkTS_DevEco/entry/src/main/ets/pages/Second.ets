// entry/src/main/ets/pages/Second.ets
import router from '@ohos.router';

@Entry @Component struct Second {
  build() {
    Stack() {
      // 全屏背景图
      Image($r("app.media.cover1"))
        .scale({ x: 1.2, y: 1.2 })
        .width("100%")
        .height("100%")
        .objectFit(ImageFit.Cover)
        .offset({ x: 5, y: 0 })
      Column() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor('#224438')
            // 点击返回上一页
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ bottom: 8 })

        Row() {
          Text('上午好，张先生')
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor('#224438')
          Blank()
          Text('南昌 26℃ 晴 ☀')
            .fontSize(17)
            .fontColor('#607870')
        }
        .width('100%')
        .margin({ bottom: 20 })

        // ==========入住信息卡片==========
        Row(){
          Image($r("app.media.room"))
            .width(160)
            .height(160)
            .borderRadius(12)
            .objectFit(ImageFit.Cover)
          Divider()
            .vertical(true)
            .height(120)
            .width(1)
            .color('#E5E7EB')
            .margin({ left: 12, right: 12 })
          Column() {
            Text('入住')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#206048')

            Text('8012')
              .fontSize(50)
              .fontWeight(FontWeight.Bold)
              .fontColor('#206048')
              .margin({top: 8})

            Text('入住：9月17日 14:00')
              .fontSize(14)
              .fontColor('#607870')
              .margin({top: 6})

            Text('退房：9月19日 12:00')
              .fontSize(14)
              .fontColor('#607870')

            // 用Row+Blank把前台按钮放到最右侧
            Row(){
              Blank()
              Button({type: ButtonType.Normal, stateEffect: true}) {
                Row() {
                  Image($r('app.media.Phone1'))
                    .width(16)
                    .height(16)
                    .fillColor(Color.White)
                  Text('前台')
                    .fontColor(Color.White)
                    .fontSize(14)
                    .margin({ left: 4 })
                }
              }
              .backgroundColor('#33CA6C')
              .borderRadius(20)
              .width(76)
              .height(32)
              .onClick(()=>{
                AlertDialog.show({
                  title: "酒店前台电话",
                  message: "📞 0791-88669955",
                  autoCancel: true,
                  alignment: DialogAlignment.Center,
                  confirm: {
                    value: "确定",
                    action: () => {}
                  }
                })
              })
            }
            .width('100%')
            .margin({top:10})
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(20)
        .shadow({radius:8, color:'#00000010', offsetX:0, offsetY:2})
        .alignItems(VerticalAlign.Center)
        .padding({left:10,right:10,top:10,bottom:10})
        .margin({bottom:24})

        Grid() {
          GridItem() {
            this.FunctionCard('app.media.Light','客房控制','灯光·空调·窗帘·其他')
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/RoomControl' })
          })
          GridItem() {
            this.FunctionCard('app.media.Public_Facilities','公共设施','洗衣房·电梯')
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/PublicFacility' })
          })
          GridItem() {
            this.FunctionCard('app.media.Room_service','客房服务','保洁·报修·续房·退房')
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/RoomService' })
          })
          GridItem() {
            this.FunctionCard('app.media.Mine','我的信息','订单·消息·设置')
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/MyInfo' })
          })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(16)
        .rowsGap(16)
        .width('100%')
      }
      .width('95%')
      .padding({ top: 12 })
      .height('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder FunctionCard(iconRes: string, title: string, desc: string) {
    Column() {
      Row() {
        Stack() {
          Circle()
            .width(48)
            .height(48)
            .fill('#60CC94')
          Image($r(iconRes))
            .width(36)
            .height(36)
            .objectFit(ImageFit.Contain)
        }
        Blank()
        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(20)
          .height(20)
          .fillColor('#224438')
      }
      .width('100%')
      .margin({ bottom: 12 })

      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#224438')
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: 4 })

      Text(desc)
        .fontSize(13)
        .fontColor('#607870')
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .aspectRatio(1)
    .padding({ top: 10, left: 10, right: 10, bottom: 10 })
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .border({ width: 5, color: Color.White, radius: 16 })
    .backgroundColor(Color.Transparent)
  }
}