# GATT（Generic Attribute Profile）详解

> GATT 是 BLE（Bluetooth Low Energy）中最核心的协议层，定义了 BLE 设备之间的数据交互方式。所有 iOS BLE 开发（CoreBluetooth）都是基于 GATT 协议进行操作的。

---

## 一、GATT 基本概念

### 1.1 什么是 GATT

GATT = **Generic Attribute Profile**（通用属性协议），建立在 ATT（Attribute Protocol）之上。

```
BLE 协议栈分层：
┌─────────────────────────────────────┐
│            Application              │ ← 你的 App 业务层
├─────────────────────────────────────┤
│              GATT                   │ ← 数据交互规范（本文）
├─────────────────────────────────────┤
│              ATT                    │ ← 属性协议（Attribute，读写操作）
├─────────────────────────────────────┤
│             L2CAP                   │ ← 逻辑链路控制与适配
├─────────────────────────────────────┤
│         Link Layer (LL)             │ ← 链路层（连接管理）
├─────────────────────────────────────┤
│         Physical Layer (PHY)        │ ← 物理层（射频）
└─────────────────────────────────────┘
```

### 1.2 GATT 角色

| 角色 | 描述 | CoreBluetooth 映射 |
|------|------|-------------------|
| **GATT Server** | 提供数据的一方（通常是外设 Peripheral） | 外设设备 `CBPeripheral` 提供 Service/Characteristic |
| **GATT Client** | 读取/写入数据的一方（通常是中心 Central） | 中心设备 `CBCentralManager` 发起读写操作 |

> ⚠️ **注意**：一个设备可以同时是 GATT Server 和 GATT Client，但实践中大多数情况是：
> - **手机 App（Central/Client）** ←→ **硬件设备（Peripheral/Server）**

---

## 二、GATT Profile 层次结构

### 2.1 结构树

```
Profile（配置文件）
  │
  ├── Service（服务）            ← 一组关联的数据和行为的集合
  │    │
  │    ├── Characteristic（特征）  ← 一条具体的数据
  │    │    ├── Properties（属性） ← 该特征支持的操作（Read/Write/Notify 等）
  │    │    ├── Value（值）       ← 实际数据内容（不超过 MTU 大小）
  │    │    └── Descriptor（描述符）← 对特征的额外描述
  │    │         ├── CCCD（0x2902）← Client Characteristic Configuration
  │    │         │     → 用于启用/禁用 Notify 或 Indicate
  │    │         ├── User Description（0x2901）
  │    │         │     → 用户可读的特征描述字符串
  │    │         └── Extended Properties（0x2900）
  │    │               → 特性的扩展属性
  │    │
  │    └── Included Service（包含的服务）
  │          → 一个 Service 可以引用另一个 Service
  │
  └── ... (多个 Service)
```

### 2.2 各层级详解

#### Service（服务）

- 由一个或多个 Characteristic 组成的逻辑集合
- 用 **UUID** 唯一标识
  - **16-bit UUID**：Bluetooth SIG 标准定义的服务（如 `0x180D` = Heart Rate Service）
  - **128-bit UUID**：自定义服务（如 `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`）
- 所有 Service 通过 Primary Service 或 Secondary Service 标记

```swift
// 标准 Service 示例
0x1800  — Generic Access Service
0x1801  — Generic Attribute Service
0x180A  — Device Information Service
0x180D  — Heart Rate Service
0x180F  — Battery Service
0x1810  — Blood Pressure Service
0x181A  — Environmental Sensing Service
```

#### Characteristic（特征）

- Service 中的最小数据单元，包含一个 Value 和 0-N 个 Descriptor
- 用 UUID 标识
- 拥有 **Properties** 表示支持的 GATT 操作

| Property | 值 | 说明 |
|----------|-----|------|
| **Read** | 0x02 | 允许 GATT Client 读取 Value |
| **Write Without Response** | 0x04 | 写入不需要回复（Write Command） |
| **Write** | 0x08 | 写入需要回复（Write Request） |
| **Notify** | 0x10 | 通知值变化（无需确认） |
| **Indicate** | 0x20 | 指示值变化（需要确认） |
| **Signed Write** | 0x40 | 签名写入 |
| **Extended Properties** | 0x80 | 还有更多属性 |

```swift
// 标准 Characteristic 示例（Heart Rate Service 0x180D）
0x2A37  — Heart Rate Measurement       (Notify)
0x2A38  — Body Sensor Location          (Read)
0x2A39  — Heart Rate Control Point      (Write)
```

#### Descriptor（描述符）

- 对 Characteristic Value 的额外说明或配置
- 关键描述符：

| UUID | 名称 | 用途 |
|------|------|------|
| **0x2900** | Characteristic Extended Properties | 特征扩展属性 |
| **0x2901** | Characteristic User Description | 用户可读的描述 |
| **0x2902** | **Client Characteristic Configuration (CCCD)** | 启用 Notify/Indicate |
| **0x2903** | Server Characteristic Configuration | 服务端配置 |
| **0x2904** | Characteristic Presentation Format | 值格式说明 |

> 🔑 **CCCD（0x2902）是最重要的描述符**，它就是你在 CoreBluetooth 中调用 `setNotifyValue(true)` 时底层写入的对象：
> - `0x0000` → 停止通知
> - `0x0001` → 启用 Notify
> - `0x0002` → 启用 Indicate

---

## 三、CoreBluetooth 与 GATT 映射关系

| GATT 概念 | CoreBluetooth 类 | 说明 |
|-----------|-----------------|------|
| GATT Client | `CBCentralManager` | 手机端为主，发起操作 |
| GATT Server | `CBPeripheral` | 硬件设备，提供数据 |
| Service | `CBService` | `peripheral.services` |
| Characteristic | `CBCharacteristic` | `service.characteristics` |
| Descriptor | `CBDescriptor` | `characteristic.descriptors` |
| CCCD | `CBDescriptor` (UUID 0x2902) | 由系统自动处理 |
| Read | `readValue(for:)` | 读取特征值 |
| Write | `writeValue(_:for:type:)` | 写入数据 |
| Write Without Response | `writeValue(_:for:type: .withoutResponse)` | 无需确认写入 |
| Notify | `setNotifyValue(true)` | 订阅通知（对应 CCCD 写入） |

### 标准发现流程

```swift
// 1. 扫描到外设 → 连接
centralManager.scanForPeripherals(withServices: [serviceUUID])

// 2. 连接成功后发现服务（GATT 层级清理）
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(nil)  // 发现所有 Service
}

// 3. 找到 Service 后，发现其下的 Characteristic
func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    for service in peripheral.services! {
        peripheral.discoverCharacteristics(nil, for: service)
    }
}

// 4. 找到 Characteristic 后，可以读写或订阅
func peripheral(_ peripheral: CBPeripheral,
                didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    for characteristic in service.characteristics! {
        if characteristic.properties.contains(.read) {
            peripheral.readValue(for: characteristic)
        }
        if characteristic.properties.contains(.notify) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
}
```

---

## 四、GATT 数据操作详解

### 4.1 Read（读取）

```
Client                          Server
  │                                │
  │──── readValue(for:) ────────→  │
  │                                │  Server 准备数据
  │←─── didUpdateValueFor ────────│
  │     (characteristic.value)     │
```

- GATT Client 发送 **Read Request**
- GATT Server 回复 **Read Response**（最多 22 字节，受 MTU 限制）
- 同步操作的串行执行，一次只能有一个待处理的 Read

### 4.2 Write（写入）

#### Write With Response（需要确认）

```
Client                          Server
  │                                │
  │──── writeValue(data, ────────→ │
  │     .withResponse)             │  Server 处理数据
  │←─── didWriteValueFor ─────────│
  │     (成功/失败回调)             │
```

- GATT Client 发送 **Write Request**
- GATT Server 回复 **Write Response**
- **可靠**但**慢**（需要等待确认）
- 适合重要数据（如控制指令）

#### Write Without Response（无需确认）

```
Client                          Server
  │                                │
  │──── writeValue(data, ────────→ │
  │     .withoutResponse)          │  不需要回复
  │   (立即返回，无回调)            │
```

- GATT Client 发送 **Write Command**
- 不需要 Server 确认
- **快**但**不可靠**
- 适合大量数据的流式传输
- 需要注意 **连接事件间隔** 和 **MTU**
- iOS 限制：一个连接事件最多可发送 N 个包（取决于协商参数）

### 4.3 Notify（通知 — 无需确认）

```
Client                          Server
  │                                │
  │ 1. 写入 CCCD = 0x0001         │
  │──── setNotifyValue(true) ────→ │
  │←─── didUpdateValueFor ────────│  Server 随时推送
  │←─── didUpdateValueFor ────────│
  │←─── didUpdateValueFor ────────│
```

- Server 主动推送数据到 Client
- Client **不需要** 回复确认
- **应用最广**的 BLE 通信方式（传感器数据上报、实时状态）

### 4.4 Indicate（指示 — 需要确认）

```
Client                          Server
  │                                │
  │ 2. 写入 CCCD = 0x0002         │
  │──── setNotifyValue(true) ────→ │
  │←─── didUpdateValueFor ────────│  Server 推送
  │──── (自动回复确认) ───────────→ │
```

- Server 推送数据到 Client
- Client 需要回复确认
- **可靠**但**慢**（下一个 Indicate 必须等上一个确认）

### 4.5 Notify vs Indicate 对比

| 对比维度 | Notify | Indicate |
|---------|--------|----------|
| 确认机制 | 无需确认 | 需要应用层确认 |
| 速度 | 快，可连续发 | 慢，串行等待确认 |
| 可靠性 | 不可靠（可能丢包） | 可靠（确保送达） |
| 适用场景 | 传感器实时数据 | 控制指令、关键事件 |
| CCCD 值 | 0x0001 | 0x0002 |

---

## 五、MTU（Maximum Transmission Unit）

### 5.1 基本概念

```
GATT 层最大数据大小 = MTU - 3（ATT 头部）

MTU = 23 字节（默认）→ 有效负载 20 字节
MTU = 247 字节（最大）→ 有效负载 244 字节
```

### 5.2 MTU 协商

```swift
// iOS 端发起 MTU 协商（CoreBluetooth 自动处理）
// 也可以通过以下方式请求更大 MTU

// iOS 请求更大的 MTU（实际大小由系统决定）
peripheral.maximumWriteValueLength(for: .withoutResponse)
// 返回当前 MTU 减去 3 后的可写长度

// 接收端获取 MTU 变更
func peripheral(_ peripheral: CBPeripheral,
                didModifyServices services: [CBService]) {
    // MTU 变更后调用
}

// 实际数据长度上限：
let mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)
// iOS 设备常见值：
//   iPhone 8:  ≤ 185 字节
//   iPhone 14+: ≤ 251 字节
```

### 5.3 MTU 与分包

当数据超过单包 MTU 限制时，需要在应用层自行分包：

```swift
/// 分包发送数据
func sendLargeData(_ data: Data, characteristic: CBCharacteristic) {
    let mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)
    let maxPacketSize = mtu  // 实际可用长度
    
    var offset = 0
    while offset < data.count {
        let chunkSize = min(maxPacketSize, data.count - offset)
        let chunk = data.subdata(in: offset..<offset + chunkSize)
        
        peripheral.writeValue(chunk, for: characteristic,
                              type: .withoutResponse)
        
        offset += chunkSize
        
        // ⚠️ 需要在包之间加延迟，避免超出连接事件窗口
        // Thread.sleep 或 Timer 控制发包间隔
    }
}
```

---

## 六、GATT 操作时序图

### 完整连接与数据交互

```
Central (iPhone)                          Peripheral (设备)
     │                                          │
     │  scanForPeripherals                       │
     │──────────────────────────────────────────→│
     │                                          │
     │  Advertisement Data (广播包)               │
     │←──────────────────────────────────────────│
     │                                          │
     │  connect(peripheral)                      │
     │──────────────────────────────────────────→│
     │                                          │
     │  === 连接建立 ===                         │
     │                                          │
     │  discoverServices(nil)                    │
     │──────────────────────────────────────────→│
     │                                          │
     │  didDiscoverServices                      │
     │←──────────────────────────────────────────│
     │                                          │
     │  discoverCharacteristics(nil, for: srv)   │
     │──────────────────────────────────────────→│
     │                                          │
     │  didDiscoverCharacteristicsFor            │
     │←──────────────────────────────────────────│
     │                                          │
     │  setNotifyValue(true, for: char)          │
     │──────────────────────────────────────────→│  ← 写入 CCCD = 0x0001
     │                                          │
     │  === 数据交互阶段 ===                      │
     │                                          │
     │           (Notify: 设备 -> 手机)          │
     │  didUpdateValueFor(char)                  │
     │←──────────────────────────────────────────│
     │  didUpdateValueFor(char)                  │
     │←──────────────────────────────────────────│
     │                                          │
     │           (Write: 手机 -> 设备)           │
     │  writeValue(data, .withResponse)          │
     │──────────────────────────────────────────→│
     │  didWriteValueFor (回调确认)               │
     │←──────────────────────────────────────────│
     │                                          │
     │  === 断开连接 ===                         │
     │  cancelPeripheralConnection                │
     │──────────────────────────────────────────→│
```

---

## 七、常见 BLE Service 和 Characteristic UUID 速查

### 标准 Service

| UUID | 名称 | 说明 |
|------|------|------|
| `0x1800` | Generic Access | 设备名称、外观等 |
| `0x1801` | Generic Attribute | GATT 服务变更等 |
| `0x180A` | Device Information | 制造商、型号、序列号等 |
| `0x180D` | Heart Rate | 心率测量、传感器位置 |
| `0x180F` | Battery Service | 电量 |
| `0x1810` | Blood Pressure | 血压 |
| `0x1812` | Human Interface Device | HID，键盘鼠标 |
| `0x181A` | Environmental Sensing | 温度/湿度/气压等 |
| `0x181C` | User Data | 用户数据 |
| `0x181D` | Weight Scale | 体重秤 |

### 常见自定义 Service 场景

| 硬件类型 | 典型自定义 Service |
|---------|------------------|
| 智能灯 | 灯光控制、色彩控制、场景模式 |
| 智能锁 | 开锁指令、门锁状态、密码管理 |
| 手环/手表 | 步数、心率、血氧、睡眠 |
| 体脂称 | 体重、体脂、BMI |
| 温湿度计 | 温度、湿度、CO₂ |

---

## 八、GATT 常见面试题

### 1. GATT 和 ATT 的区别是什么？

**ATT（Attribute Protocol）** 是底层协议，定义了属性（Attribute）的读写操作（Request/Response/Command/Notification）。**GATT** 是建立在 ATT 之上的高级协议，定义了如何组织数据（Profile → Service → Characteristic → Descriptor）以及业务交互规范。简单说：ATT 管怎么传，GATT 管传什么。

### 2. Notify 和 Indicate 有什么区别？怎么选？

Notify 无需确认，速度快但不保证送达；Indicate 需要应用层确认，可靠但速度慢。传感器实时数据用 Notify，控制指令/关键事件用 Indicate。

### 3. BLE 一次能传多少字节数据？

默认 MTU = 23 字节，ATT 头占 3 字节，有效负载 = 20 字节。协商后 iOS 最大可达 251 字节（有效负载 248 字节）。超过需要自行分包发送。

### 4. 什么是 CCCD？它在 BLE 中的作用是什么？

CCCD（Client Characteristic Configuration Descriptor，UUID 0x2902）是 Characteristic 的配置描述符。写入 0x0001 启用 Notify，0x0002 启用 Indicate，0x0000 关闭。CoreBluetooth 的 `setNotifyValue(true)` 底层就是在 CCCD 写值。

### 5. GATT Profile 的层级结构是怎样的？

Profile → Service（UUID）→ Characteristic（UUID + Properties + Value）→ Descriptor（UUID）。一个 Profile 包含多个 Service，每个 Service 包含多个 Characteristic，每个 Characteristic 包含若干 Descriptor。

### 6. 如何处理 BLE 的数据分包与粘包？

**分包**：当数据超过 MTU 时，自定义分包协议（如 2 字节包头 + 2 字节包序号 + N 字节数据），接收端根据序号重组。

**粘包**：Notify 数据频繁时可能连续收到多个包，需要在应用层做缓存和解析，根据包长度字段或结束标记切分。

### 7. 什么是 Primary Service 和 Secondary Service？

Primary Service 是设备主要功能的服务（如心率设备的 Heart Rate Service），暴露给外部扫描。Secondary Service 被 Primary Service 内部引用（`Included Service`），不直接在广播中暴露。

### 8. BLE 连接参数有哪些？怎么优化？

- **Connection Interval**：连接事件间隔（7.5ms ~ 4s），间隔越小响应越快但耗电
- **Slave Latency**：从设备可跳过的连接事件数，越大越省电
- **Supervision Timeout**：超时时间（100ms ~ 32s）

```swift
// iOS 端无法主动修改连接参数（由 Peripheral 在固件中定义）
// 但可以通过 negotiate 请求或重新连接来更新
```

---

## 九、GATT 最佳实践

| 场景 | 推荐方案 |
|------|---------|
| 传感器数据上报（心率、温度） | Notify（速度快、无确认开销） |
| 设备控制指令（开灯、开锁） | Write With Response（确保送达） |
| OTA 固件升级大数据传输 | Write Without Response + 分包 + 流控 |
| 设备信息读取（序列号、版本） | Read（一次性读取） |
| 多设备连接 | 每个 Peripheral 独立管理状态机 |
| 断线重连 | 保存 Identifier + 使用 `retrievePeripherals(withIdentifiers:)` |
| 数据完整性校验 | 应用层加 CRC 或校验和 |

---

## 附录：GATT 标准 UUID 表

```text
$services: {
  "0x1800": "Generic Access",
  "0x1801": "Generic Attribute",
  "0x180A": "Device Information",
  "0x180D": "Heart Rate",
  "0x180F": "Battery Service",
  "0x1810": "Blood Pressure",
  "0x1812": "Human Interface Device",
  "0x181A": "Environmental Sensing"
}

$characteristics: {
  "0x2A00": "Device Name",
  "0x2A01": "Appearance",
  "0x2A02": "Peripheral Privacy Flag",
  "0x2A19": "Battery Level",
  "0x2A24": "Model Number String",
  "0x2A25": "Serial Number String",
  "0x2A26": "Firmware Revision String",
  "0x2A27": "Hardware Revision String",
  "0x2A28": "Software Revision String",
  "0x2A29": "Manufacturer Name String",
  "0x2A37": "Heart Rate Measurement",
  "0x2A38": "Body Sensor Location",
  "0x2A39": "Heart Rate Control Point"
}

$descriptors: {
  "0x2900": "Characteristic Extended Properties",
  "0x2901": "Characteristic User Description",
  "0x2902": "Client Characteristic Configuration (CCCD)",
  "0x2903": "Server Characteristic Configuration",
  "0x2904": "Characteristic Presentation Format"
}
```
