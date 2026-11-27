// entry/src/main/ets/pages/PublicFacility.ets
// 公共设施页面
import router from '@ohos.router';
import { DeviceService } from '../common/DeviceService';

// 洗衣设备模型
class WashDevice {
  id: number
  name: string
  type: string
  floor: string
  status: string //空闲、使用中、故障
  remainTime: string

  constructor(id: number, name: string, type: string, floor: string, status: string, remainTime: string = "") {
    this.id = id
    this.name = name
    this.type = type
    this.floor = floor
    this.status = status
    this.remainTime = remainTime
  }
}

//电梯模型
class ElevatorInfo {
  name: string;
  floor: number;
  direction: string;
  dirIcon: string;
  status: string;
  constructor(name: string, floor: number, direction: string, dirIcon: string, status: string) {
    this.name = name;
    this.floor = floor;
    this.direction = direction;
    this.dirIcon = dirIcon;
    this.status = status;
  }
}

@Entry
@Component
struct PublicFacilityPage {
  @State currentTab: number = 0 //0洗衣房，1电梯
  //洗衣设备静态数据
  @State washDeviceList: WashDevice[] = [
    new WashDevice(1, "1号洗衣机", "洗衣机", "1F", "空闲"),
    new WashDevice(2, "2号洗衣机", "洗衣机", "1F", "使用中", "剩余25分钟"),
    new WashDevice(3, "3号洗衣机", "洗衣机", "2F", "空闲"),
    new WashDevice(4, "4号烘干机", "烘干机", "2F", "空闲"),
    new WashDevice(5, "5号烘干机", "烘干机", "2F", "故障"),
    new WashDevice(6, "6号洗衣机", "洗衣机", "3F", "空闲"),
  ]
  @State washTime: string = ""
  //电梯静态数据，截图：1号12F上行，2号8F上行，3号6F下行，4号满载
  @State elevatorList: ElevatorInfo[] = [
    new ElevatorInfo("1号电梯",12,"上行","↑","正常"),
    new ElevatorInfo("2号电梯",8,"上行","↑","正常"),
    new ElevatorInfo("3号电梯",6,"下行","↓","正常"),
    new ElevatorInfo("4号电梯",1,"满载","⚠","满载"),
  ]
  @State callElevatorTip: string = ""

  build() {
    Column() {
      //顶部标题栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor("#333")
          .onClick(() => {
            router.back()
          })
        Blank()
        Text("公共设施").fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Text("").width(24)
      }
      .width('100%')
      .padding({ left:16, right:16, top:8, bottom:12 })

      //顶部Tab栏：洗衣房 / 电梯
      Row() {
        Button("🧺 洗衣房")
          .layoutWeight(1)
          .backgroundColor(this.currentTab === 0 ? "#36b37e" : "#eeeeee")
          .fontColor(this.currentTab ===0 ? "#fff":"#333")
          .onClick(()=>{ this.currentTab = 0 })
        Button("🛗 电梯")
          .layoutWeight(1)
          .backgroundColor(this.currentTab === 1 ? "#36b37e" : "#eeeeee")
          .fontColor(this.currentTab ===1 ? "#fff":"#333")
          .onClick(()=>{ this.currentTab = 1 })
      }
      .width('92%')
      .height(44)
      .borderRadius(22)
      .margin({bottom:16})

      //Tab内容区域
      if(this.currentTab ===0){
        //==================== 洗衣房页面 ====================
        Scroll(){
          Column(){
            //顶部卡片简介
            Column(){
              Row(){
                Image($r("app.media.SmartHotel1"))
                  .width(36)
                  .height(36)
                Column(){
                  Text("洗衣房").fontSize(18).fontWeight(FontWeight.Bold)
                  Text("让出行更轻松 便捷·高效").fontSize(14).fontColor("#666")
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Blank()
                Text("24小时开放").fontSize(14).fontColor("#36b37e")
              }
              .width('100%')

              Row() {
                Column(){
                  Text("当前可用洗衣机").fontSize(12).fontColor("#666")
                  Text("2 台").fontSize(18).fontColor("#36b37e").fontWeight(FontWeight.Bold)
                }
                Blank()
                Column(){
                  Text("当前可用烘干机").fontSize(12).fontColor("#666")
                  Text("1 台").fontSize(18).fontColor("#ff9500").fontWeight(FontWeight.Bold)
                }
              }
              .width('100%')
              .margin({top:12})
            }
            .width('92%')
            .padding(16)
            .backgroundColor("#ffffff")
            .borderRadius(12)

            //设备列表标题
            Row(){
              Text("设备列表").fontSize(16).fontWeight(FontWeight.Bold)
              Blank()
              Text("共 6 台设备").fontSize(12).fontColor("#777")
            }
            .width('92%')
            .margin({top:16, bottom:8})

            //设备列表循环
            ForEach(this.washDeviceList,(item:WashDevice)=>{
              Row(){
                Column(){
                  Text(item.name).fontSize(15)
                  Text(`${item.type} | ${item.floor}`).fontSize(11).fontColor("#777")
                }
                Blank()
                //状态标签
                if(item.status === "空闲"){
                  Text(item.status)
                    .fontSize(12)
                    .fontColor("#fff")
                    .backgroundColor("#36b37e")
                    .padding({left:10,right:10,top:4,bottom:4})
                    .borderRadius(12)
                }else if(item.status === "使用中"){
                  Column(){
                    Text(item.status)
                      .fontSize(12)
                      .fontColor("#fff")
                      .backgroundColor("#ff9500")
                      .padding({left:10,right:10,top:4,bottom:4})
                      .borderRadius(12)
                    Text(item.remainTime).fontSize(10).fontColor("#ff9500").margin({top:2})
                  }
                }else if(item.status === "故障"){
                  Text(item.status)
                    .fontSize(12)
                    .fontColor("#fff")
                    .backgroundColor("#f53f3f")
                    .padding({left:10,right:10,top:4,bottom:4})
                    .borderRadius(12)
                }
              }
              .width('92%')
              .padding(14)
              .backgroundColor("#fff")
              .borderRadius(10)
              .margin({bottom:8})
            })

            Blank().height(20)
            // 底部预约按钮（第四张图：控制闸道开门）
            Button("📅 立即预约空闲设备")
              .width('92%')
              .height(50)
              .backgroundColor("#36b37e")
              .fontColor("#fff")
              .borderRadius(25)
              .onClick(()=>{
                AlertDialog.show({
                  title:"预约洗衣设备",
                  message:"确认预约空闲设备并开启公共门禁闸道？",
                  buttons:[
                    {
                      value:"取消",
                      action:()=>{}
                    },
                    {
                      value:"确认预约并开闸",
                      action:()=>{
                        DeviceService.control('gate_test');
                        DeviceService.showToast("预约成功！洗衣房闸道已开启 🚪");
                      }
                    }
                  ]
                })
              })
            Blank().height(30)
          }
          .width('100%')
        }
        .width('100%')
      }else{
        //==================== 电梯页面 ====================
        Scroll(){
          Column(){
            //电梯头部卡片
            Row(){
              Text("🛗").fontSize(32).margin({right:10})
              Column(){
                Text("电梯实时状态").fontSize(18).fontWeight(FontWeight.Bold)
                Text("4部电梯 · 运行正常").fontSize(12).fontColor("#777")
              }
              Blank()
              Column(){
                Text("当前楼层").fontSize(12).fontColor("#777")
                Text("12F").fontSize(20).fontWeight(FontWeight.Bold)
              }
            }
            .width('92%')
            .padding(16)
            .backgroundColor("#fff")
            .borderRadius(12)

            //电梯轨道区域
            Row() {
              // 左侧楼层刻度
              Column() {
                ForEach([40, 35, 30, 25, 20, 15, 10, 5, 1], (floor: number) => {
                  Text(`${floor}F`)
                    .fontSize(11)
                    .fontColor("#666666")
                    .width(24)
                    .textAlign(TextAlign.End)
                    .margin({ bottom: 33 })
                })
              }
              .height(320)
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ right: 8 })
              //4台电梯列
              ForEach(this.elevatorList,(elev:ElevatorInfo)=>{
                Column(){
                  Text(elev.name).fontSize(13).fontWeight(FontWeight.Bold)
                  Blank()
                  //电梯轿厢
                  Column(){
                    if(elev.name==="4号电梯"){
                      Text("⚠满载").fontSize(11).fontColor("#fff").backgroundColor("#f53f3f").borderRadius(12).padding({left:6,right:6})
                    }else{
                      Text(elev.direction === "up" ? "↑上行":"↓下行").fontSize(11).fontColor("#fff").backgroundColor("#36b37e").borderRadius(12).padding({left:6,right:6})
                    }
                    Text(`${elev.floor}F`).fontSize(14).fontWeight(FontWeight.Bold).margin({top:4})
                  }
                  .width(40)
                  .height(50)
                  .backgroundColor("#e8f5f0")
                  .borderRadius(8)
                  .justifyContent(FlexAlign.Center)
                  Blank()
                }
                .height(320)
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              })
            }
            .width('92%')
            .height(320)
            .margin({top:16})

            // 呼叫电梯卡片（第五张图：控制闸道开门）
            Row(){
              Text("🔔").fontSize(26)
              Column(){
                Text("呼叫电梯").fontSize(16).fontWeight(FontWeight.Bold)
                Text(this.callElevatorTip || "已为您呼叫，预计30秒后到达当前楼层").fontSize(11).fontColor("#777")
              }
              Blank()
              Text(">").fontSize(22).fontColor("#36b37e")
            }
            .width('92%')
            .padding(16)
            .backgroundColor("#fff")
            .borderRadius(12)
            .margin({top:16})
            .onClick(()=>{
              this.callElevatorTip = "呼叫已下发，闸道已开启";
              AlertDialog.show({
                title:"呼叫电梯",
                message:"确认呼叫电梯到当前12层并开启电梯闸道？",
                buttons:[
                  {value:"取消",action:()=>{}},
                  {
                    value:"确定开闸",
                    action:()=>{
                      DeviceService.control('gate_test');
                      DeviceService.showToast("电梯已呼叫，门禁闸道已开启 🚪");
                    }
                  }
                ]
              })
            })

            //底部小字
            Row(){
              Text("🛡️智能电梯").fontSize(11).fontColor("#777")
              Blank()
              Text("⚡高效便捷").fontSize(11).fontColor("#777")
              Blank()
              Text("❤️舒适出行").fontSize(11).fontColor("#777")
            }
            .width('80%')
            .margin({top:20})
            Blank().height(30)
          }
          .width('100%')
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#f7f8fa")
  }
}
