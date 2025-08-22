<template>
  <div class="builder">
    <el-container>
      <el-header class="header">
        <div class="header-content">
          <div class="logo">
            <h2>EZ-Theme 构建器</h2>
          </div>
          <div class="nav">
            <el-menu
              mode="horizontal"
              :default-active="activeIndex"
              @select="handleSelect"
              background-color="transparent"
              text-color="#fff"
              active-text-color="#409eff"
            >
              <el-menu-item index="/">首页</el-menu-item>
              <el-menu-item index="/builder">主题构建</el-menu-item>
              <el-menu-item index="/builds">构建记录</el-menu-item>
              <el-menu-item index="/payment">充值</el-menu-item>
              <el-menu-item v-if="isAdmin" index="/admin">管理后台</el-menu-item>
            </el-menu>
          </div>
          <div class="user-info">
            <el-dropdown @command="handleCommand">
              <span class="user-dropdown">
                {{ user?.username }}
                <el-icon><ArrowDown /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="profile">个人资料</el-dropdown-item>
                  <el-dropdown-item command="logout">退出登录</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </div>
      </el-header>

      <el-main>
        <div class="container">
          <div class="page-header">
            <h1 class="page-title">主题构建器</h1>
            <p class="page-subtitle">自定义配置您的EZ-Theme主题</p>
          </div>

          <el-row :gutter="20">
            <el-col :span="16">
              <div class="config-panel">
                <el-tabs v-model="activeTab" type="border-card">
                  <!-- 基础配置 -->
                  <el-tab-pane label="基础配置" name="basic">
                    <div class="form-section">
                      <h3>面板类型</h3>
                      <div class="config-item">
                        <label>面板类型</label>
                        <el-select v-model="config.PANEL_TYPE" placeholder="选择面板类型">
                          <el-option label="V2board" value="V2board" />
                          <el-option label="Xiao-V2board" value="Xiao-V2board" />
                          <el-option label="Xboard" value="Xboard" />
                        </el-select>
                      </div>
                    </div>

                    <div class="form-section">
                      <h3>网站信息</h3>
                      <div class="config-item">
                        <label>网站名称</label>
                        <el-input v-model="config.SITE_CONFIG.siteName" placeholder="输入网站名称" />
                      </div>
                      <div class="config-item">
                        <label>网站描述</label>
                        <el-input v-model="config.SITE_CONFIG.siteDescription" placeholder="输入网站描述" />
                      </div>
                      <div class="config-item">
                        <label>主题色</label>
                        <el-color-picker v-model="config.DEFAULT_CONFIG.primaryColor" />
                      </div>
                    </div>

                    <div class="form-section">
                      <h3>默认设置</h3>
                      <div class="config-item">
                        <label>默认语言</label>
                        <el-select v-model="config.DEFAULT_CONFIG.defaultLanguage">
                          <el-option label="中文简体" value="zh-CN" />
                          <el-option label="English" value="en-US" />
                        </el-select>
                      </div>
                      <div class="config-item">
                        <label>默认主题</label>
                        <el-select v-model="config.DEFAULT_CONFIG.defaultTheme">
                          <el-option label="浅色" value="light" />
                          <el-option label="深色" value="dark" />
                        </el-select>
                      </div>
                      <div class="config-item">
                        <label>启用落地页</label>
                        <el-switch v-model="config.DEFAULT_CONFIG.enableLandingPage" />
                      </div>
                    </div>
                  </el-tab-pane>

                  <!-- API配置 -->
                  <el-tab-pane label="API配置" name="api">
                    <div class="form-section">
                      <h3>API设置</h3>
                      <div class="config-item">
                        <label>URL获取方式</label>
                        <el-select v-model="config.API_CONFIG.urlMode">
                          <el-option label="静态URL" value="static" />
                          <el-option label="自动获取" value="auto" />
                        </el-select>
                      </div>
                      <div class="config-item" v-if="config.API_CONFIG.urlMode === 'static'">
                        <label>静态基础URL</label>
                        <el-input v-model="config.API_CONFIG.staticBaseUrl[0]" placeholder="/api/v1" />
                      </div>
                      <div class="config-item">
                        <label>启用中间件代理</label>
                        <el-switch v-model="config.API_MIDDLEWARE_ENABLED" />
                      </div>
                      <div class="config-item">
                        <label>静默API检测</label>
                        <el-switch v-model="config.SILENT_API_CHECK" />
                      </div>
                    </div>
                  </el-tab-pane>

                  <!-- 功能配置 -->
                  <el-tab-pane label="功能配置" name="features">
                                         <div class="form-section">
                       <h3>商店功能</h3>
                       <div class="config-item">
                         <label>显示热销标记</label>
                         <el-switch v-model="config.SHOP_CONFIG.showHotSaleBadge" />
                       </div>
                       <div class="config-item">
                         <label>显示套餐特性卡片</label>
                         <el-switch v-model="config.SHOP_CONFIG.showPlanFeatureCards" />
                       </div>
                       <div class="config-item">
                         <label>自动选择最大周期</label>
                         <el-switch v-model="config.SHOP_CONFIG.autoSelectMaxPeriod" />
                       </div>
                       <div class="config-item">
                         <label>隐藏周期标签页</label>
                         <el-switch v-model="config.SHOP_CONFIG.hidePeriodTabs" />
                       </div>
                       <div class="config-item">
                         <label>低库存阈值</label>
                         <el-input-number v-model="config.SHOP_CONFIG.lowStockThreshold" :min="1" :max="100" />
                       </div>
                       <div class="config-item">
                         <label>启用折扣计算</label>
                         <el-switch v-model="config.SHOP_CONFIG.enableDiscountCalculation" />
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>商店弹窗</h3>
                       <div class="config-item">
                         <label>启用商店弹窗</label>
                         <el-switch v-model="config.SHOP_CONFIG.popup.enabled" />
                       </div>
                       <div class="config-item" v-if="config.SHOP_CONFIG.popup.enabled">
                         <label>弹窗标题</label>
                         <el-input v-model="config.SHOP_CONFIG.popup.title" placeholder="用户须知" />
                       </div>
                       <div class="config-item" v-if="config.SHOP_CONFIG.popup.enabled">
                         <label>弹窗内容</label>
                         <el-input 
                           v-model="config.SHOP_CONFIG.popup.content" 
                           type="textarea" 
                           :rows="3"
                           placeholder="常规套餐默认每月订单日重置流量"
                         />
                       </div>
                       <div class="config-item" v-if="config.SHOP_CONFIG.popup.enabled">
                         <label>弹窗冷却时间</label>
                         <el-input-number v-model="config.SHOP_CONFIG.popup.cooldownHours" :min="0" :max="168" />
                         <span class="form-help">小时</span>
                       </div>
                       <div class="config-item" v-if="config.SHOP_CONFIG.popup.enabled">
                         <label>关闭等待时间</label>
                         <el-input-number v-model="config.SHOP_CONFIG.popup.closeWaitSeconds" :min="0" :max="60" />
                         <span class="form-help">秒</span>
                       </div>
                     </div>

                    <div class="form-section">
                      <h3>仪表盘功能</h3>
                      <div class="config-item">
                        <label>显示用户邮箱</label>
                        <el-switch v-model="config.DASHBOARD_CONFIG.showUserEmail" />
                      </div>
                      <div class="config-item">
                        <label>启用重置流量</label>
                        <el-switch v-model="config.DASHBOARD_CONFIG.enableResetTraffic" />
                      </div>
                      <div class="config-item">
                        <label>启用续费套餐</label>
                        <el-switch v-model="config.DASHBOARD_CONFIG.enableRenewPlan" />
                      </div>
                      <div class="config-item">
                        <label>显示在线设备限制</label>
                        <el-switch v-model="config.DASHBOARD_CONFIG.showOnlineDevicesLimit" />
                      </div>
                                             <div class="config-item">
                         <label>显示导入订阅按钮</label>
                         <el-switch v-model="config.DASHBOARD_CONFIG.showImportSubscription" />
                       </div>
                       <div class="config-item">
                         <label>导入按钮高亮背景</label>
                         <el-switch v-model="config.DASHBOARD_CONFIG.importButtonHighlightBtnbgcolor" />
                       </div>
                                              <div class="config-item">
                         <label>客户端连接数限制</label>
                         <el-input-number 
                           v-model="config.DASHBOARD_CONFIG.clientConnectionLimit" 
                           :min="1" 
                           :max="999"
                           placeholder="输入连接数限制"
                         />
                         <span class="form-help">个设备</span>
                       </div>
                       <div class="config-item">
                         <label>重置流量显示模式</label>
                         <el-select v-model="config.DASHBOARD_CONFIG.resetTrafficDisplayMode">
                           <el-option label="低流量时显示" value="low" />
                           <el-option label="始终显示" value="always" />
                           <el-option label="隐藏" value="hidden" />
                         </el-select>
                       </div>
                       <div class="config-item">
                         <label>低流量阈值</label>
                         <el-input-number v-model="config.DASHBOARD_CONFIG.lowTrafficThreshold" :min="1" :max="1000" />
                         <span class="form-help">GB</span>
                       </div>
                       <div class="config-item">
                         <label>续费套餐显示模式</label>
                         <el-select v-model="config.DASHBOARD_CONFIG.renewPlanDisplayMode">
                           <el-option label="始终显示" value="always" />
                           <el-option label="即将到期时显示" value="expiring" />
                           <el-option label="隐藏" value="hidden" />
                         </el-select>
                       </div>
                       <div class="config-item">
                         <label>即将到期阈值</label>
                         <el-input-number v-model="config.DASHBOARD_CONFIG.expiringThreshold" :min="1" :max="30" />
                         <span class="form-help">天</span>
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>流量日志配置</h3>
                       <div class="config-item">
                         <label>启用流量日志</label>
                         <el-switch v-model="config.TRAFFICLOG_CONFIG.enableTrafficLog" />
                       </div>
                       <div class="config-item" v-if="config.TRAFFICLOG_CONFIG.enableTrafficLog">
                         <label>显示天数</label>
                         <el-input-number v-model="config.TRAFFICLOG_CONFIG.daysToShow" :min="7" :max="90" />
                         <span class="form-help">天</span>
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>节点配置</h3>
                       <div class="config-item">
                         <label>显示节点速率</label>
                         <el-switch v-model="config.NODES_CONFIG.showNodeRate" />
                       </div>
                       <div class="config-item">
                         <label>显示节点详情</label>
                         <el-switch v-model="config.NODES_CONFIG.showNodeDetails" />
                       </div>
                       <div class="config-item">
                         <label>允许查看节点信息</label>
                         <el-switch v-model="config.NODES_CONFIG.allowViewNodeInfo" />
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>个人资料配置</h3>
                       <div class="config-item">
                         <label>显示礼品卡兑换</label>
                         <el-switch v-model="config.PROFILE_CONFIG.showGiftCardRedeem" />
                       </div>
                       <div class="config-item">
                         <label>显示最近设备</label>
                         <el-switch v-model="config.PROFILE_CONFIG.showRecentDevices" />
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>邀请配置</h3>
                       <div class="config-item">
                         <label>显示佣金徽章</label>
                         <el-switch v-model="config.INVITE_CONFIG.showCommissionBadge" />
                       </div>
                       <div class="config-item">
                         <label>每页记录数</label>
                         <el-input-number v-model="config.INVITE_CONFIG.recordsPerPage" :min="5" :max="50" />
                       </div>
                       <div class="config-item">
                         <label>邀请链接模式</label>
                         <el-select v-model="config.INVITE_CONFIG.inviteLinkConfig.linkMode">
                           <el-option label="自动生成" value="auto" />
                           <el-option label="自定义域名" value="custom" />
                         </el-select>
                       </div>
                       <div class="config-item" v-if="config.INVITE_CONFIG.inviteLinkConfig.linkMode === 'custom'">
                         <label>自定义域名</label>
                         <el-input v-model="config.INVITE_CONFIG.inviteLinkConfig.customDomain" placeholder="https://example.com" />
                       </div>
                     </div>

                                         <div class="form-section">
                       <h3>客户端下载</h3>
                       <div class="config-item">
                         <label>显示下载卡片</label>
                         <el-switch v-model="config.CLIENT_CONFIG.showDownloadCard" />
                       </div>
                       <div class="config-item">
                         <label>显示iOS客户端</label>
                         <el-switch v-model="config.CLIENT_CONFIG.showIOS" />
                       </div>
                       <div class="config-item">
                         <label>显示Android客户端</label>
                         <el-switch v-model="config.CLIENT_CONFIG.showAndroid" />
                       </div>
                       <div class="config-item">
                         <label>显示Windows客户端</label>
                         <el-switch v-model="config.CLIENT_CONFIG.showWindows" />
                       </div>
                       <div class="config-item">
                         <label>显示MacOS客户端</label>
                         <el-switch v-model="config.CLIENT_CONFIG.showMacOS" />
                       </div>
                       <div class="config-item">
                         <label>显示Linux客户端</label>
                         <el-switch v-model="config.CLIENT_CONFIG.showLinux" />
                       </div>
                       <div class="config-item">
                         <label>显示OpenWrt客户端</label>
                         <el-switch v-model="config.CLIENT_CONFIG.showOpenWrt" />
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>自定义下载链接</h3>
                       <div class="config-item">
                         <label>iOS下载链接</label>
                         <el-input v-model="config.CLIENT_CONFIG.clientLinks.ios" placeholder="https://apps.apple.com/ca/app/shadowrocket/id932747118" />
                       </div>
                       <div class="config-item">
                         <label>Android下载链接</label>
                         <el-input v-model="config.CLIENT_CONFIG.clientLinks.android" placeholder="https://github.com/wxfyes/FlClash/releases" />
                       </div>
                       <div class="config-item">
                         <label>Windows下载链接</label>
                         <el-input v-model="config.CLIENT_CONFIG.clientLinks.windows" placeholder="https://github.com/wxfyes/FlClash/releases" />
                       </div>
                       <div class="config-item">
                         <label>MacOS下载链接</label>
                         <el-input v-model="config.CLIENT_CONFIG.clientLinks.macos" placeholder="https://github.com/wxfyes/FlClash/releases" />
                       </div>
                       <div class="config-item">
                         <label>Linux下载链接</label>
                         <el-input v-model="config.CLIENT_CONFIG.clientLinks.linux" placeholder="https://github.com/wxfyes/FlClash/releases" />
                       </div>
                       <div class="config-item">
                         <label>OpenWrt下载链接</label>
                         <el-input v-model="config.CLIENT_CONFIG.clientLinks.openwrt" placeholder="https://github.com/xxx/releases/latest" />
                       </div>
                     </div>
                  </el-tab-pane>

                  <!-- 高级配置 -->
                  <el-tab-pane label="高级配置" name="advanced">
                    <div class="form-section">
                      <h3>安全配置</h3>
                      <div class="config-item">
                        <label>启用前端域名验证</label>
                        <el-switch v-model="config.SECURITY_CONFIG.enableFrontendDomainCheck" />
                      </div>
                      <div class="config-item" v-if="config.SECURITY_CONFIG.enableFrontendDomainCheck">
                        <label>授权域名</label>
                        <el-input
                          v-model="config.AUTHORIZED_DOMAINS"
                          type="textarea"
                          :rows="3"
                          placeholder="每行一个域名"
                        />
                      </div>
                    </div>

                    <div class="form-section">
                      <h3>验证码配置</h3>
                      <div class="config-item">
                        <label>验证方式</label>
                        <el-select v-model="config.CAPTCHA_CONFIG.captchaType">
                          <el-option label="Google reCAPTCHA" value="google" />
                          <el-option label="Cloudflare Turnstile" value="cloudflare" />
                        </el-select>
                      </div>
                    </div>

                                         <div class="form-section">
                       <h3>支付配置</h3>
                       <div class="config-item">
                         <label>新标签页打开支付</label>
                         <el-switch v-model="config.PAYMENT_CONFIG.openPaymentInNewTab" />
                       </div>
                       <div class="config-item">
                         <label>自动检测支付状态</label>
                         <el-switch v-model="config.PAYMENT_CONFIG.autoCheckPayment" />
                       </div>
                       <div class="config-item">
                         <label>支付二维码大小</label>
                         <el-input-number v-model="config.PAYMENT_CONFIG.qrcodeSize" :min="100" :max="400" />
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>工单配置</h3>
                       <div class="config-item">
                         <label>工单中包含用户信息</label>
                         <el-switch v-model="config.TICKET_CONFIG.includeUserInfoInTicket" />
                       </div>
                       <div class="config-item">
                         <label>启用工单弹窗</label>
                         <el-switch v-model="config.TICKET_CONFIG.popup.enabled" />
                       </div>
                       <div class="config-item" v-if="config.TICKET_CONFIG.popup.enabled">
                         <label>工单弹窗标题</label>
                         <el-input v-model="config.TICKET_CONFIG.popup.title" placeholder="工单须知" />
                       </div>
                       <div class="config-item" v-if="config.TICKET_CONFIG.popup.enabled">
                         <label>工单弹窗内容</label>
                         <el-input 
                           v-model="config.TICKET_CONFIG.popup.content" 
                           type="textarea" 
                           :rows="3"
                           placeholder="请您准确描述您的问题，再提交工单，以便我们更快帮助您。"
                         />
                       </div>
                       <div class="config-item" v-if="config.TICKET_CONFIG.popup.enabled">
                         <label>弹窗冷却时间</label>
                         <el-input-number v-model="config.TICKET_CONFIG.popup.cooldownHours" :min="0" :max="168" />
                         <span class="form-help">小时</span>
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>图床配置</h3>
                       <div class="config-item">
                         <label>启用图片上传</label>
                         <el-switch v-model="config.TICKET_CONFIG.imageUpload.enabled" />
                       </div>
                       <div class="config-item" v-if="config.TICKET_CONFIG.imageUpload.enabled">
                         <label>上传方式</label>
                         <el-select v-model="config.TICKET_CONFIG.imageUpload.uploadMethod">
                           <el-option label="图床" value="imagebed" />
                           <el-option label="WebDAV" value="webdav" />
                         </el-select>
                       </div>
                       <div class="config-item" v-if="config.TICKET_CONFIG.imageUpload.enabled">
                         <label>最大文件数</label>
                         <el-input-number v-model="config.TICKET_CONFIG.imageUpload.maxFiles" :min="1" :max="20" />
                       </div>
                       <div class="config-item" v-if="config.TICKET_CONFIG.imageUpload.enabled">
                         <label>最大文件大小</label>
                         <el-input-number v-model="config.TICKET_CONFIG.imageUpload.maxSize" :min="1024000" :max="10485760" />
                         <span class="form-help">字节</span>
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>钱包配置</h3>
                       <div class="config-item">
                         <label>预设金额</label>
                         <el-input 
                           :model-value="config.WALLET_CONFIG.presetAmounts.join(',')"
                           @input="(val) => config.WALLET_CONFIG.presetAmounts = val.split(',').map(v => parseInt(v.trim())).filter(v => !isNaN(v))"
                           placeholder="50,100,200,300,400,500,600,800"
                         />
                         <span class="form-help">用逗号分隔</span>
                       </div>
                       <div class="config-item">
                         <label>默认选中金额</label>
                         <el-input-number v-model="config.WALLET_CONFIG.defaultSelectedAmount" :min="0" />
                         <span class="form-help">0表示不默认选中</span>
                       </div>
                       <div class="config-item">
                         <label>最小充值金额</label>
                         <el-input-number v-model="config.WALLET_CONFIG.minimumDepositAmount" :min="1" />
                       </div>
                     </div>

                     <div class="form-section">
                       <h3>浏览器限制配置</h3>
                       <div class="config-item">
                         <label>启用浏览器限制</label>
                         <el-switch v-model="config.BROWSER_RESTRICT_CONFIG.enabled" />
                       </div>
                       <div class="config-item" v-if="config.BROWSER_RESTRICT_CONFIG.enabled">
                         <label>限制360浏览器</label>
                         <el-switch v-model="config.BROWSER_RESTRICT_CONFIG.restrictBrowsers['360']" />
                       </div>
                       <div class="config-item" v-if="config.BROWSER_RESTRICT_CONFIG.enabled">
                         <label>限制QQ浏览器</label>
                         <el-switch v-model="config.BROWSER_RESTRICT_CONFIG.restrictBrowsers['QQ']" />
                       </div>
                       <div class="config-item" v-if="config.BROWSER_RESTRICT_CONFIG.enabled">
                         <label>限制微信浏览器</label>
                         <el-switch v-model="config.BROWSER_RESTRICT_CONFIG.restrictBrowsers['WeChat']" />
                       </div>
                       <div class="config-item" v-if="config.BROWSER_RESTRICT_CONFIG.enabled">
                         <label>限制百度浏览器</label>
                         <el-switch v-model="config.BROWSER_RESTRICT_CONFIG.restrictBrowsers['Baidu']" />
                       </div>
                       <div class="config-item" v-if="config.BROWSER_RESTRICT_CONFIG.enabled">
                         <label>限制搜狗浏览器</label>
                         <el-switch v-model="config.BROWSER_RESTRICT_CONFIG.restrictBrowsers['Sogou']" />
                       </div>
                     </div>
                  </el-tab-pane>
                </el-tabs>
              </div>
            </el-col>

            <el-col :span="8">
              <div class="preview-panel">
                <div class="card">
                  <h3>构建预览</h3>
                  <div class="preview-content">
                    <div class="preview-item">
                      <strong>面板类型:</strong> {{ config.PANEL_TYPE }}
                    </div>
                    <div class="preview-item">
                      <strong>网站名称:</strong> {{ config.SITE_CONFIG.siteName }}
                    </div>
                    <div class="preview-item">
                      <strong>主题色:</strong> 
                      <span class="color-preview" :style="{ backgroundColor: config.DEFAULT_CONFIG.primaryColor }"></span>
                      {{ config.DEFAULT_CONFIG.primaryColor }}
                    </div>
                    <div class="preview-item">
                      <strong>默认语言:</strong> {{ config.DEFAULT_CONFIG.defaultLanguage }}
                    </div>
                                         <div class="preview-item">
                       <strong>默认主题:</strong> {{ config.DEFAULT_CONFIG.defaultTheme }}
                     </div>
                     <div class="preview-item">
                       <strong>客户端连接限制:</strong> {{ config.DASHBOARD_CONFIG.clientConnectionLimit }} 个设备
                     </div>
                     <div class="preview-item">
                       <strong>显示导入订阅:</strong> {{ config.DASHBOARD_CONFIG.showImportSubscription ? '是' : '否' }}
                     </div>
                   </div>
                </div>

                <div class="card">
                  <h3>构建信息</h3>
                  <div class="build-info">
                    <div class="info-item">
                      <span>当前余额:</span>
                      <span class="credits">{{ user?.credits || 0 }}</span>
                    </div>
                    <div class="info-item">
                      <span>构建费用:</span>
                      <span>{{ systemConfig.price_per_build || 10 }}</span>
                    </div>
                    <div class="info-item">
                      <span>剩余次数:</span>
                      <span>{{ Math.floor((user?.credits || 0) / (systemConfig.price_per_build || 10)) }}</span>
                    </div>
                  </div>
                </div>

                <div class="card">
                  <h3>操作</h3>
                  <div class="action-buttons">
                    <el-button 
                      type="primary" 
                      size="large" 
                      :loading="building"
                      :disabled="!canBuild"
                      @click="handleBuild"
                      style="width: 100%; margin-bottom: 1rem;"
                    >
                      开始构建
                    </el-button>
                    <el-button 
                      @click="resetConfig"
                      style="width: 100%;"
                    >
                      重置配置
                    </el-button>
                  </div>
                </div>
              </div>
            </el-col>
          </el-row>
        </div>
      </el-main>
    </el-container>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

export default {
  name: 'Builder',
  setup() {
    const router = useRouter()
    const route = useRoute()
    const authStore = useAuthStore()
    
    const activeIndex = ref('/builder')
    const activeTab = ref('basic')
    const building = ref(false)
    const systemConfig = ref({})

    const user = computed(() => authStore.user)
    const isAdmin = computed(() => authStore.isAdmin)

    // 默认配置
    const config = reactive({
      PANEL_TYPE: 'Xiao-V2board',
      API_CONFIG: {
        urlMode: 'static',
        staticBaseUrl: ['/api/v1'],
        autoConfig: {
          useSameProtocol: true,
          appendApiPath: true,
          apiPath: '/api/v1'
        }
      },
      API_MIDDLEWARE_ENABLED: false,
      SILENT_API_CHECK: true,
      API_CHECK_TIMEOUT: 3000,
      API_CHECK_CACHE_ENABLED: true,
      API_CHECK_CACHE_DURATION: 300000,
      API_MIDDLEWARE_URL: '',
      API_MIDDLEWARE_PATH: '/ez/ez',
      SITE_CONFIG: {
        siteName: '我的主题',
        siteDescription: '自定义EZ-Theme',
        copyright: `© ${new Date().getFullYear()} EZ THEME. All Rights Reserved.`,
        showLogo: true,
        landingText: {
          'zh-CN': '探索全球网络无限可能',
          'en-US': 'Explore Unlimited Possibilities of Global Network'
        },
        customLandingPage: ''
      },
      DEFAULT_CONFIG: {
        defaultLanguage: 'zh-CN',
        defaultTheme: 'light',
        primaryColor: '#355cc2',
        enableLandingPage: false
      },
      AUTH_CONFIG: {
        autoAgreeTerms: true,
        verificationCode: {
          showCheckSpamTip: true,
          checkSpamTipDelay: 1000
        },
        popup: {
          enabled: false,
          title: "用户须知",
          content: "<p>欢迎使用我们的服务！</p>",
          cooldownHours: 0,
          closeWaitSeconds: 3
        }
      },
      AUTH_LAYOUT_CONFIG: {
        layoutType: 'split',
        splitLayout: {
          leftContent: {
            backgroundImage: 'https://www.loliapi.com/acg',
            siteName: {
              show: true,
              color: 'white'
            },
            greeting: {
              show: true,
              color: 'white'
            }
          }
        }
      },
      SHOP_CONFIG: {
        showHotSaleBadge: false,
        showPlanFeatureCards: true,
        autoSelectMaxPeriod: false,
        hidePeriodTabs: false,
        lowStockThreshold: 5,
        enableDiscountCalculation: true,
        periodOrder: [
          'three_year_price',
          'two_year_price',
          'year_price',
          'half_year_price',
          'quarter_price',
          'month_price',
          'onetime_price'
        ],
        popup: {
          enabled: true,
          title: "用户须知",
          content: "<p>常规套餐默认每月订单日重置流量</p>",
          cooldownHours: 0,
          closeWaitSeconds: 0
        }
      },
      ORDER_CONFIG: {
        confirmOrder: true,
        confirmOrderContent: "<p>无法提供相关教程和使用说明。</p>"
      },
             DASHBOARD_CONFIG: {
         showUserEmail: false,
         importButtonHighlightBtnbgcolor: true,
         enableResetTraffic: true,
         resetTrafficDisplayMode: 'low',
         lowTrafficThreshold: 10,
         enableRenewPlan: true,
         renewPlanDisplayMode: 'always',
         expiringThreshold: 7,
         showOnlineDevicesLimit: true,
         showImportSubscription: true,
         clientConnectionLimit: 3
       },
      CLIENT_CONFIG: {
        showDownloadCard: true,
        showIOS: true,
        showAndroid: true,
        showMacOS: true,
        showWindows: true,
        showLinux: true,
        showOpenWrt: false,
        clientLinks: {
          ios: 'https://apps.apple.com/ca/app/shadowrocket/id932747118',
          android: 'https://github.com/wxfyes/FlClash/releases',
          macos: 'https://github.com/wxfyes/FlClash/releases',
          windows: 'https://github.com/wxfyes/FlClash/releases',
          linux: 'https://github.com/wxfyes/FlClash/releases',
          openwrt: 'https://github.com/xxx/releases/latest'
        },
        showShadowrocket: true,
        showSurge: true,
        showStash: true,
        showQuantumultX: true,
        showHiddifyIOS: true,
        showSingboxIOS: true,
        showLoon: true,
        showFlClashAndroid: true,
        showV2rayNG: true,
        showClashAndroid: true,
        showSurfboard: true,
        showClashMetaAndroid: true,
        showNekobox: true,
        showSingboxAndroid: true,
        showHiddifyAndroid: true,
        showFlClashWindows: true,
        showClashVergeWindows: true,
        showClashWindows: true,
        showNekoray: true,
        showSingboxWindows: true,
        showHiddifyWindows: true,
        showFlClashMac: true,
        showClashVergeMac: true,
        showClashX: true,
        showClashMetaX: true,
        showSurgeMac: true,
        showStashMac: true,
        showQuantumultXMac: true,
        showSingboxMac: true,
        showHiddifyMac: true
      },
      PROFILE_CONFIG: {
        showGiftCardRedeem: true,
        showRecentDevices: true
      },
      SECURITY_CONFIG: {
        enableFrontendDomainCheck: false
      },
      AUTHORIZED_DOMAINS: [
        "test.eztheme.test",
        "test1.eztheme.test"
      ],
      CAPTCHA_CONFIG: {
        captchaType: 'google',
        google: {
          verifyUrl: 'https://www.google.com/recaptcha/api/siteverify'
        },
        cloudflare: {
          verifyUrl: 'https://challenges.cloudflare.com/turnstile/v0/siteverify'
        }
      },
      CUSTOM_HEADERS: {
        enabled: false,
        headers: {}
      },
      PAYMENT_CONFIG: {
        openPaymentInNewTab: true,
        qrcodeSize: 200,
        qrcodeColor: '#000000',
        qrcodeBackground: '#ffffff',
        autoCheckPayment: true,
        autoCheckInterval: 5000,
        autoCheckMaxTimes: 60,
        useSafariPaymentModal: true,
        autoSelectFirstMethod: true
      },
      WALLET_CONFIG: {
        presetAmounts: [50, 100, 200, 300, 400, 500, 600, 800],
        defaultSelectedAmount: null,
        minimumDepositAmount: 1
      },
      INVITE_CONFIG: {
        showCommissionBadge: true,
        recordsPerPage: 10,
        inviteLinkConfig: {
          linkMode: 'auto',
          customDomain: 'https://example.com'
        }
      },
      BROWSER_RESTRICT_CONFIG: {
        enabled: false,
        restrictBrowsers: {
          '360': true,
          'QQ': true,
          'WeChat': true,
          'Baidu': true,
          'Sogou': true,
          'UC': false,
          'Maxthon': false
        },
        recommendedBrowsers: {
          'Chrome': 'https://www.google.cn/chrome/',
          'Edge': 'https://www.microsoft.com/edge'
        }
      },
      TICKET_CONFIG: {
        includeUserInfoInTicket: true,
        popup: {
          enabled: true,
          title: "工单须知",
          content: "<p>请您准确描述您的问题，再提交工单，以便我们更快帮助您。</p>",
          cooldownHours: 24,
          closeWaitSeconds: 0
        },
        imageUpload: {
          enabled: true,
          uploadMethod: 'imagebed',
          maxFiles: 5,
          maxSize: 5242880,
          webdav: {
            serverUrl: 'https://dav.jianguoyun.com/dav',
            username: 'your-email@example.com',
            password: 'your-app-password',
            uploadPath: '/images',
            publicUrl: 'https://your-public-url.com/images'
          },
          imageBeds: [
            {
              name: 'ImgBB',
              type: 'imgbb',
              apiUrl: 'https://api.imgbb.com/1/upload',
              apiKey: '85719aefcab7c40a7eaed3b06784898a',
              enabled: true,
              priority: 1,
              description: '免费图床，支持直接链接'
            }
          ],
          imageBedStrategy: {
            method: 'priority',
            enableFailover: true,
            maxRetries: 3,
            retryDelay: 1000
          }
        }
      },
      TRAFFICLOG_CONFIG: {
        enableTrafficLog: true,
        daysToShow: 30
      },
      NODES_CONFIG: {
        showNodeRate: true,
        showNodeDetails: false,
        allowViewNodeInfo: true
      },
      CUSTOMER_SERVICE_CONFIG: {
        enabled: false,
        type: 'crisp',
        customHtml: '',
        embedMode: 'embed',
        showWhenNotLoggedIn: true,
        iconPosition: {
          desktop: {
            left: '20px',
            bottom: '20px'
          },
          mobile: {
            right: '20px',
            bottom: '100px'
          }
        }
      },
      MORE_PAGE_CONFIG: {
        enableCustomCards: false,
        customCards: []
      }
    })

    const canBuild = computed(() => {
      return (user.value?.credits || 0) >= (systemConfig.value.price_per_build || 10)
    })

    const handleSelect = (key) => {
      router.push(key)
    }

    const handleCommand = (command) => {
      if (command === 'profile') {
        router.push('/profile')
      } else if (command === 'logout') {
        authStore.logout()
        router.push('/login')
        ElMessage.success('已退出登录')
      }
    }

    const resetConfig = async () => {
      try {
        await ElMessageBox.confirm('确定要重置所有配置吗？', '确认重置', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        
        // 重置配置到默认值
        Object.assign(config, {
          PANEL_TYPE: 'Xiao-V2board',
          SITE_CONFIG: {
            siteName: '我的主题',
            siteDescription: '自定义EZ-Theme',
            copyright: `© ${new Date().getFullYear()} EZ THEME. All Rights Reserved.`,
            showLogo: true,
            landingText: {
              'zh-CN': '探索全球网络无限可能',
              'en-US': 'Explore Unlimited Possibilities of Global Network'
            },
            customLandingPage: ''
          },
          DEFAULT_CONFIG: {
            defaultLanguage: 'zh-CN',
            defaultTheme: 'light',
            primaryColor: '#355cc2',
            enableLandingPage: false
          }
        })
        
        ElMessage.success('配置已重置')
      } catch {
        // 用户取消
      }
    }

    const handleBuild = async () => {
      if (!canBuild.value) {
        ElMessage.error('余额不足，请先充值')
        router.push('/payment')
        return
      }

      try {
        await ElMessageBox.confirm(
          `确定要开始构建吗？将扣除 ${systemConfig.value.price_per_build || 10} 积分`,
          '确认构建',
          {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'info'
          }
        )

        building.value = true
        
        const response = await axios.post('/api/builds/create', {
          config_data: config
        })

        ElMessage.success('构建已开始，请稍后查看结果')
        router.push('/builds')
      } catch (error) {
        if (error.response?.status === 402) {
          ElMessage.error('余额不足，请先充值')
          router.push('/payment')
        } else if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else {
          ElMessage.error('构建失败，请重试')
        }
      } finally {
        building.value = false
      }
    }

    const fetchSystemConfig = async () => {
      try {
        const response = await axios.get('/api/system/config')
        systemConfig.value = response.data.config
      } catch (error) {
        console.error('获取系统配置失败:', error)
      }
    }

    onMounted(() => {
      fetchSystemConfig()
    })

    return {
      activeIndex,
      activeTab,
      building,
      systemConfig,
      user,
      isAdmin,
      config,
      canBuild,
      handleSelect,
      handleCommand,
      resetConfig,
      handleBuild
    }
  }
}
</script>

<style scoped>
.header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0;
  height: 60px;
}

.header-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.logo h2 {
  margin: 0;
  color: white;
}

.nav {
  flex: 1;
  display: flex;
  justify-content: center;
}

.user-info {
  display: flex;
  align-items: center;
}

.user-dropdown {
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 5px;
}

.config-panel {
  margin-bottom: 2rem;
}

.preview-panel {
  position: sticky;
  top: 20px;
}

.preview-content {
  margin-top: 1rem;
}

.preview-item {
  margin-bottom: 0.5rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.preview-item:last-child {
  border-bottom: none;
}

.color-preview {
  display: inline-block;
  width: 20px;
  height: 20px;
  border-radius: 4px;
  margin-right: 8px;
  vertical-align: middle;
}

.build-info {
  margin-top: 1rem;
}

.info-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.info-item:last-child {
  border-bottom: none;
}

.credits {
  font-weight: bold;
  color: #409eff;
}

 .action-buttons {
   margin-top: 1rem;
 }

 .form-help {
   margin-left: 0.5rem;
   color: #666;
   font-size: 0.875rem;
 }

 .config-item {
   margin-bottom: 1.5rem;
 }

 .config-item label {
   display: block;
   margin-bottom: 0.5rem;
   font-weight: 500;
   color: #333;
 }

 .form-section {
   margin-bottom: 2rem;
   padding: 1.5rem;
   background: #f8f9fa;
   border-radius: 8px;
   border: 1px solid #e9ecef;
 }

 .form-section h3 {
   margin-top: 0;
   margin-bottom: 1.5rem;
   color: #495057;
   font-size: 1.1rem;
   border-bottom: 2px solid #dee2e6;
   padding-bottom: 0.5rem;
 }

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    height: auto;
    padding: 1rem 20px;
  }
  
  .nav {
    margin: 1rem 0;
  }
  
  .preview-panel {
    position: static;
    margin-top: 2rem;
  }
}
</style>
