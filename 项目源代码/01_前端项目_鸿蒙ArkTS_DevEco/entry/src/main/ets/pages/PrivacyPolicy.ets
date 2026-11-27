import router from '@ohos.router';

@Entry
@Component
struct PrivacyPolicy {
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
        Text("隐私政策")
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
          Text("云栖酒店隐私政策\n\n1. 我们会收集您的手机号用于登录与入住核验。\n2. 您的个人信息仅用于酒店服务，不会出售给第三方。\n3. 您有权申请查看、删除您的个人数据。\n4. 系统会采取加密方式保护您的信息安全。\n5. 如不同意本隐私政策，请停止使用本系统。")
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