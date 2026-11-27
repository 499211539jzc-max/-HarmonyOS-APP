import router from '@ohos.router';

@Entry
@Component
struct UserAgreement {
  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor("#333")
          .onClick(() => {
            router.back()
          })
        Text("用户协议")
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .width('100%')
      .padding({left:12,right:12,top:16,bottom:16})

      Scroll() {
        Column() {
          Text("云栖酒店用户协议\n\n1. 用户使用本小程序/APP即代表同意本协议。\n2. 用户应当如实填写入住信息，保证信息真实有效。\n3. 禁止利用本系统从事违法活动。\n4. 酒店有权对违规用户暂停服务。\n5. 本协议最终解释权归云栖酒店所有。")
            .fontSize(15)
            .fontColor("#333")
            .lineHeight(28)
        }
        .padding(16)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#ffffff")
    .expandSafeArea()
  }
}