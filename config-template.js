/**
 * 外部配置文件
 * 由EZ-Theme构建器自动生成
 * index.html 中可以搜索 EZ 将其替换为您的网站名称
 * logo 摆放位置为 images/logo.png
 */

export const config = {
    // 面板类型配置 - 请选择您使用的面板类型
    PANEL_TYPE: '{{PANEL_TYPE}}', // 可选值: 'V2board', 'Xiao-V2board' 或 'Xboard'

    // =======================================================

    // API配置
    API_CONFIG: {
        // API URL获取方式: 'static'=使用静态URL, 'auto'=自动从当前域名获取
        urlMode: '{{API_CONFIG.urlMode}}',

        // 静态URL模式下的基础URL (urlMode = 'static'时使用)
        // 支持字符串形式(单个API地址)或数组形式(多个备选API地址)
        staticBaseUrl: {{API_CONFIG.staticBaseUrl}},

        // 自动获取模式配置 (urlMode = 'auto'时使用)
        autoConfig: {
            // 是否使用相同协议 (http/https)
            useSameProtocol: {{API_CONFIG.autoConfig.useSameProtocol}},

            // 是否拼接API路径
            appendApiPath: {{API_CONFIG.autoConfig.appendApiPath}},

            // API路径
            apiPath: '{{API_CONFIG.autoConfig.apiPath}}'
        }
    },

    // 是否启用中间件代理API请求
    API_MIDDLEWARE_ENABLED: {{API_MIDDLEWARE_ENABLED}},

    // 是否启用静默API可用性检测
    SILENT_API_CHECK: {{SILENT_API_CHECK}},

    // API检测超时时间（毫秒）
    API_CHECK_TIMEOUT: {{API_CHECK_TIMEOUT}},

    // 是否启用API检测缓存
    API_CHECK_CACHE_ENABLED: {{API_CHECK_CACHE_ENABLED}},

    // API检测缓存时间（毫秒）
    API_CHECK_CACHE_DURATION: {{API_CHECK_CACHE_DURATION}},

    // 中间件服务器URL (不含路径)
    API_MIDDLEWARE_URL: '{{API_MIDDLEWARE_URL}}',

    // 中间件路由前缀 (与中间件服务器配置保持一致)
    API_MIDDLEWARE_PATH: '{{API_MIDDLEWARE_PATH}}',

    //=======================================================

    // ====================  网站基础配置  ====================
    SITE_CONFIG: {
        siteName: '{{SITE_CONFIG.siteName}}',
        siteDescription: '{{SITE_CONFIG.siteDescription}}',
        // copyright会自动使用当前年份
        copyright: `© ${new Date().getFullYear()} EZ THEME. All Rights Reserved.`,

        // 是否显示标题中的网站Logo (true=显示, false=隐藏)
        showLogo: {{SITE_CONFIG.showLogo}},

        // Landing页面多语言标语
        landingText: {{SITE_CONFIG.landingText}},

        // 自定义landing页面路径（相对于public目录
        customLandingPage: '{{SITE_CONFIG.customLandingPage}}'
    },

    // 默认语言和主题配置
    DEFAULT_CONFIG: {
        defaultLanguage: '{{DEFAULT_CONFIG.defaultLanguage}}',
        defaultTheme: '{{DEFAULT_CONFIG.defaultTheme}}',
        primaryColor: '{{DEFAULT_CONFIG.primaryColor}}',
        enableLandingPage: {{DEFAULT_CONFIG.enableLandingPage}}
    },

    // 认证配置
    AUTH_CONFIG: {
        autoAgreeTerms: {{AUTH_CONFIG.autoAgreeTerms}},
        verificationCode: {
            showCheckSpamTip: {{AUTH_CONFIG.verificationCode.showCheckSpamTip}},
            checkSpamTipDelay: {{AUTH_CONFIG.verificationCode.checkSpamTipDelay}}
        },
        popup: {
            enabled: {{AUTH_CONFIG.popup.enabled}},
            title: "{{AUTH_CONFIG.popup.title}}",
            content: "{{AUTH_CONFIG.popup.content}}",
            cooldownHours: {{AUTH_CONFIG.popup.cooldownHours}},
            closeWaitSeconds: {{AUTH_CONFIG.popup.closeWaitSeconds}}
        }
    }
};

window.EZ_CONFIG = config;
