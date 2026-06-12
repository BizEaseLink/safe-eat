import Foundation

/// 参数化配置项（对应后端 app_config_params 表）
/// 客户端只读 API 返回的字段：key/value/paramType/scope/description
struct ConfigParamItem: Codable, Identifiable {
    var id: String { key }

    let key: String
    let value: String
    let paramType: String
    let scope: String
    let description: String?
}

/// 批量拉取参数的响应格式（后端返回 { items: [...] }）
struct ConfigParamListResponse: Decodable {
    let items: [ConfigParamItem]
}