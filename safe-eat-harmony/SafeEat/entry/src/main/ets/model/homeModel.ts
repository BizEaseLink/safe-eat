// 用户信息类型
export interface UserInfo {
  userId: string;
  userName: string;
  avatar: string; // 头像URL
  role: string; // 用户角色（如admin/user）
}

// 功能项类型（对应Home页功能卡片）
export interface FunctionItem {
  functionId: string;
  functionName: string;
  icon: string; // 图标资源名（如"icon_task"）
  path: string; // 跳转页面路径（如"pages/TaskPage"）
  badgeCount?: number; // 角标数量（可选）
}

// Home页整体数据类型
export interface HomeData {
  userInfo: UserInfo;
  welcomeText: string; // 欢迎语（如"欢迎回来，张三"）
  recommendList: string[]; // 推荐内容列表
  updateTime: string; // 数据更新时间
}