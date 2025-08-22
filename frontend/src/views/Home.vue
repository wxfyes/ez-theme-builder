<template>
  <div class="home">
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
            <h1 class="page-title">欢迎使用 EZ-Theme 构建器</h1>
            <p class="page-subtitle">快速构建您的专属主题，支持宝塔面板一键安装</p>
          </div>

          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-icon">
                <el-icon><Wallet /></el-icon>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ user?.credits || 0 }}</div>
                <div class="stat-label">当前余额</div>
              </div>
            </div>

            <div class="stat-card">
              <div class="stat-icon">
                <el-icon><Setting /></el-icon>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ systemConfig.price_per_build || 10 }}</div>
                <div class="stat-label">每次构建费用</div>
              </div>
            </div>

            <div class="stat-card">
              <div class="stat-icon">
                <el-icon><Document /></el-icon>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ buildCount }}</div>
                <div class="stat-label">构建次数</div>
              </div>
            </div>
          </div>

          <div class="action-cards">
            <div class="card">
              <h3>快速开始</h3>
              <p>立即开始构建您的专属主题，支持自定义配置</p>
              <el-button type="primary" @click="$router.push('/builder')">
                开始构建
              </el-button>
            </div>

            <div class="card">
              <h3>查看记录</h3>
              <p>查看您的构建历史记录和下载已完成的主题</p>
              <el-button @click="$router.push('/builds')">
                查看记录
              </el-button>
            </div>

            <div class="card">
              <h3>账户充值</h3>
              <p>充值余额以继续使用构建服务</p>
              <el-button type="success" @click="$router.push('/payment')">
                立即充值
              </el-button>
            </div>
          </div>

          <div class="features-section">
            <h2>功能特色</h2>
            <div class="features-grid">
              <div class="feature-item">
                <el-icon><Setting /></el-icon>
                <h4>可视化配置</h4>
                <p>通过网页界面轻松配置主题参数，无需手动编辑代码</p>
              </div>
              <div class="feature-item">
                <el-icon><Download /></el-icon>
                <h4>一键安装</h4>
                <p>生成的包支持宝塔面板一键安装，快速部署</p>
              </div>
              <div class="feature-item">
                <el-icon><Lock /></el-icon>
                <h4>安全可靠</h4>
                <p>API密钥验证，确保只有授权用户才能使用服务</p>
              </div>
              <div class="feature-item">
                <el-icon><Refresh /></el-icon>
                <h4>实时构建</h4>
                <p>实时查看构建进度，支持构建状态监控</p>
              </div>
            </div>
          </div>
        </div>
      </el-main>
    </el-container>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import axios from 'axios'

export default {
  name: 'Home',
  setup() {
    const router = useRouter()
    const route = useRoute()
    const authStore = useAuthStore()
    
    const activeIndex = ref('/')
    const systemConfig = ref({})
    const buildCount = ref(0)

    const user = computed(() => authStore.user)
    const isAdmin = computed(() => authStore.isAdmin)

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

    const fetchSystemConfig = async () => {
      try {
        const response = await axios.get('/api/system/config')
        systemConfig.value = response.data.config
      } catch (error) {
        console.error('获取系统配置失败:', error)
      }
    }

    const fetchBuildCount = async () => {
      try {
        const response = await axios.get('/api/builds?limit=1')
        buildCount.value = response.data.pagination.total
      } catch (error) {
        console.error('获取构建数量失败:', error)
      }
    }

    onMounted(() => {
      activeIndex.value = route.path
      fetchSystemConfig()
      fetchBuildCount()
    })

    return {
      activeIndex,
      user,
      isAdmin,
      systemConfig,
      buildCount,
      handleSelect,
      handleCommand
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 1rem;
}

.stat-icon {
  font-size: 2rem;
  color: #409eff;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: bold;
  color: #333;
}

.stat-label {
  color: #666;
  font-size: 0.9rem;
}

.action-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
  margin-bottom: 3rem;
}

.card {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  text-align: center;
}

.card h3 {
  margin-bottom: 1rem;
  color: #333;
}

.card p {
  margin-bottom: 1.5rem;
  color: #666;
}

.features-section {
  margin-top: 3rem;
}

.features-section h2 {
  text-align: center;
  margin-bottom: 2rem;
  color: #333;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.feature-item {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  text-align: center;
}

.feature-item .el-icon {
  font-size: 2rem;
  color: #409eff;
  margin-bottom: 1rem;
}

.feature-item h4 {
  margin-bottom: 0.5rem;
  color: #333;
}

.feature-item p {
  color: #666;
  font-size: 0.9rem;
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
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .action-cards {
    grid-template-columns: 1fr;
  }
  
  .features-grid {
    grid-template-columns: 1fr;
  }
}
</style>
