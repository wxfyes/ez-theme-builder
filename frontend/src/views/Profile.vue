<template>
  <div class="profile">
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
            <h1 class="page-title">个人资料</h1>
            <p class="page-subtitle">管理您的账户信息和API密钥</p>
          </div>

          <el-row :gutter="20">
            <el-col :span="16">
              <div class="profile-panel">
                <el-tabs v-model="activeTab">
                  <el-tab-pane label="基本信息" name="basic">
                    <div class="profile-form">
                      <el-form 
                        ref="profileForm" 
                        :model="profileForm" 
                        :rules="profileRules" 
                        label-width="120px"
                      >
                        <el-form-item label="用户名" prop="username">
                          <el-input v-model="profileForm.username" disabled />
                        </el-form-item>
                        
                        <el-form-item label="邮箱地址" prop="email">
                          <el-input v-model="profileForm.email" disabled />
                        </el-form-item>
                        
                        <el-form-item label="注册时间">
                          <el-input :value="formatDate(user?.created_at)" disabled />
                        </el-form-item>
                        
                        <el-form-item label="当前余额">
                          <el-input :value="`${user?.credits || 0} 积分`" disabled />
                        </el-form-item>
                        
                        <el-form-item label="账户类型">
                          <el-tag :type="user?.is_admin ? 'danger' : 'success'">
                            {{ user?.is_admin ? '管理员' : '普通用户' }}
                          </el-tag>
                        </el-form-item>
                      </el-form>
                    </div>
                  </el-tab-pane>

                  <el-tab-pane label="API密钥" name="api">
                    <div class="api-section">
                      <div class="api-info">
                        <h3>API密钥管理</h3>
                        <p>您的API密钥用于程序化构建主题，请妥善保管。</p>
                        
                        <div class="api-key-display">
                          <div class="key-header">
                            <span>当前API密钥:</span>
                            <el-button @click="copyApiKey" size="small" type="primary">
                              复制密钥
                            </el-button>
                          </div>
                          <div class="key-value">
                            {{ user?.api_key }}
                          </div>
                        </div>

                        <div class="api-warning">
                          <el-alert
                            title="安全提醒"
                            type="warning"
                            :closable="false"
                            show-icon
                          >
                            <ul>
                              <li>请勿将API密钥泄露给他人</li>
                              <li>如发现密钥泄露，请立即联系管理员重置</li>
                              <li>API密钥具有与您账户相同的权限</li>
                            </ul>
                          </el-alert>
                        </div>

                        <div class="api-usage">
                          <h4>API使用示例</h4>
                          <div class="code-example">
                            <pre><code>curl -X POST "{{ apiBaseUrl }}/api/builds/create-with-key" \
  -H "X-API-Key: {{ user?.api_key }}" \
  -H "Content-Type: application/json" \
  -d '{
    "config_data": {
      "SITE_CONFIG": {
        "siteName": "我的主题"
      },
      "DEFAULT_CONFIG": {
        "primaryColor": "#355cc2"
      }
    }
  }'</code></pre>
                          </div>
                        </div>
                      </div>
                    </div>
                  </el-tab-pane>

                  <el-tab-pane label="使用统计" name="stats">
                    <div class="stats-section">
                      <div class="stats-grid">
                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><Document /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ buildStats.total || 0 }}</div>
                            <div class="stat-label">总构建次数</div>
                          </div>
                        </div>

                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><Check /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ buildStats.completed || 0 }}</div>
                            <div class="stat-label">成功构建</div>
                          </div>
                        </div>

                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><Close /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ buildStats.failed || 0 }}</div>
                            <div class="stat-label">失败构建</div>
                          </div>
                        </div>

                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><Wallet /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ buildStats.totalSpent || 0 }}</div>
                            <div class="stat-label">总消费积分</div>
                          </div>
                        </div>
                      </div>

                      <div class="recent-builds">
                        <h3>最近构建记录</h3>
                        <div class="builds-list" v-loading="loadingStats">
                          <div v-if="recentBuilds.length === 0 && !loadingStats" class="empty-builds">
                            <p>暂无构建记录</p>
                            <el-button type="primary" @click="$router.push('/builder')">
                              开始构建
                            </el-button>
                          </div>

                          <div v-else class="build-item" v-for="build in recentBuilds" :key="build.build_id">
                            <div class="build-info">
                              <div class="build-header">
                                <h4>构建 #{{ build.build_id }}</h4>
                                <span :class="['status-badge', `status-${build.status}`]">
                                  {{ getStatusText(build.status) }}
                                </span>
                              </div>
                              <div class="build-details">
                                <p>创建时间: {{ formatDate(build.created_at) }}</p>
                              </div>
                            </div>
                            <div class="build-actions">
                              <el-button 
                                v-if="build.status === 'completed'"
                                type="primary" 
                                size="small"
                                @click="downloadBuild(build.build_id)"
                              >
                                下载
                              </el-button>
                              <el-button 
                                v-if="build.status === 'pending' || build.status === 'processing'"
                                size="small"
                                @click="checkStatus(build.build_id)"
                              >
                                检查状态
                              </el-button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </el-tab-pane>
                </el-tabs>
              </div>
            </el-col>

            <el-col :span="8">
              <div class="info-panel">
                <div class="card">
                  <h3>账户概览</h3>
                  <div class="account-overview">
                    <div class="overview-item">
                      <span>用户名:</span>
                      <span>{{ user?.username }}</span>
                    </div>
                    <div class="overview-item">
                      <span>邮箱:</span>
                      <span>{{ user?.email }}</span>
                    </div>
                    <div class="overview-item">
                      <span>当前余额:</span>
                      <span class="credits">{{ user?.credits || 0 }}</span>
                    </div>
                    <div class="overview-item">
                      <span>账户类型:</span>
                      <el-tag :type="user?.is_admin ? 'danger' : 'success'" size="small">
                        {{ user?.is_admin ? '管理员' : '普通用户' }}
                      </el-tag>
                    </div>
                  </div>
                </div>

                <div class="card">
                  <h3>快速操作</h3>
                  <div class="quick-actions">
                    <el-button 
                      type="primary" 
                      @click="$router.push('/builder')"
                      style="width: 100%; margin-bottom: 1rem;"
                    >
                      开始构建
                    </el-button>
                    <el-button 
                      @click="$router.push('/builds')"
                      style="width: 100%; margin-bottom: 1rem;"
                    >
                      查看构建记录
                    </el-button>
                    <el-button 
                      type="success" 
                      @click="$router.push('/payment')"
                      style="width: 100%;"
                    >
                      充值余额
                    </el-button>
                  </div>
                </div>

                <div class="card">
                  <h3>系统信息</h3>
                  <div class="system-info">
                    <div class="info-item">
                      <span>构建费用:</span>
                      <span>{{ systemConfig.price_per_build || 10 }} 积分/次</span>
                    </div>
                    <div class="info-item">
                      <span>每日限制:</span>
                      <span>{{ systemConfig.max_builds_per_day || 5 }} 次</span>
                    </div>
                    <div class="info-item">
                      <span>支持面板:</span>
                      <span>V2board, Xiao-V2board, Xboard</span>
                    </div>
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
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import axios from 'axios'
import dayjs from 'dayjs'

export default {
  name: 'Profile',
  setup() {
    const router = useRouter()
    const route = useRoute()
    const authStore = useAuthStore()
    
    const activeIndex = ref('/profile')
    const activeTab = ref('basic')
    const loadingStats = ref(false)
    const systemConfig = ref({})
    const buildStats = ref({})
    const recentBuilds = ref([])

    const user = computed(() => authStore.user)
    const isAdmin = computed(() => authStore.isAdmin)
    const apiBaseUrl = computed(() => window.location.origin)

    const profileForm = ref({
      username: user.value?.username || '',
      email: user.value?.email || ''
    })

    const profileRules = {
      username: [
        { required: true, message: '请输入用户名', trigger: 'blur' }
      ],
      email: [
        { required: true, message: '请输入邮箱地址', trigger: 'blur' },
        { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
      ]
    }

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

    const formatDate = (date) => {
      if (!date) return '-'
      return dayjs(date).format('YYYY-MM-DD HH:mm:ss')
    }

    const copyApiKey = async () => {
      try {
        await navigator.clipboard.writeText(user.value?.api_key || '')
        ElMessage.success('API密钥已复制到剪贴板')
      } catch (error) {
        ElMessage.error('复制失败')
      }
    }

    const getStatusText = (status) => {
      const statusMap = {
        pending: '等待中',
        processing: '处理中',
        completed: '已完成',
        failed: '失败'
      }
      return statusMap[status] || status
    }

    const downloadBuild = async (buildId) => {
      try {
        const response = await axios.get(`/api/builds/${buildId}/download`, {
          responseType: 'blob'
        })
        
        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', `ez-theme-${buildId}.zip`)
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        window.URL.revokeObjectURL(url)
        
        ElMessage.success('下载开始')
      } catch (error) {
        ElMessage.error('下载失败')
        console.error('下载失败:', error)
      }
    }

    const checkStatus = async (buildId) => {
      try {
        const response = await axios.get(`/api/builds/${buildId}`)
        const build = response.data
        
        // 更新本地构建状态
        const index = recentBuilds.value.findIndex(b => b.build_id === buildId)
        if (index !== -1) {
          recentBuilds.value[index] = build
        }
        
        if (build.status === 'completed') {
          ElMessage.success('构建已完成！')
        } else if (build.status === 'failed') {
          ElMessage.error('构建失败')
        } else {
          ElMessage.info('构建仍在进行中')
        }
      } catch (error) {
        ElMessage.error('检查状态失败')
        console.error('检查状态失败:', error)
      }
    }

    const loadStats = async () => {
      loadingStats.value = true
      try {
        // 获取构建统计
        const buildsResponse = await axios.get('/api/builds?limit=100')
        const builds = buildsResponse.data.builds || []
        
        // 计算统计信息
        const stats = {
          total: builds.length,
          completed: builds.filter(b => b.status === 'completed').length,
          failed: builds.filter(b => b.status === 'failed').length,
          totalSpent: builds.length * (systemConfig.value.price_per_build || 10)
        }
        
        buildStats.value = stats
        recentBuilds.value = builds.slice(0, 5) // 最近5个构建
      } catch (error) {
        console.error('加载统计信息失败:', error)
      } finally {
        loadingStats.value = false
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
      loadStats()
    })

    return {
      activeIndex,
      activeTab,
      loadingStats,
      systemConfig,
      buildStats,
      recentBuilds,
      user,
      isAdmin,
      apiBaseUrl,
      profileForm,
      profileRules,
      handleSelect,
      handleCommand,
      formatDate,
      copyApiKey,
      getStatusText,
      downloadBuild,
      checkStatus
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

.profile-panel {
  margin-bottom: 2rem;
}

.profile-form {
  max-width: 600px;
}

.api-section {
  max-width: 800px;
}

.api-info h3 {
  margin-bottom: 1rem;
  color: #333;
}

.api-info p {
  color: #666;
  margin-bottom: 2rem;
}

.api-key-display {
  background: #f5f5f5;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.key-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  font-weight: 500;
}

.key-value {
  background: #fff;
  padding: 1rem;
  border-radius: 4px;
  font-family: monospace;
  word-break: break-all;
  font-size: 0.875rem;
  border: 1px solid #e5e7eb;
}

.api-warning {
  margin-bottom: 2rem;
}

.api-warning ul {
  margin: 0.5rem 0 0 0;
  padding-left: 1.5rem;
}

.api-warning li {
  margin-bottom: 0.25rem;
}

.api-usage h4 {
  margin-bottom: 1rem;
  color: #333;
}

.code-example {
  background: #1e1e1e;
  border-radius: 8px;
  padding: 1.5rem;
  overflow-x: auto;
}

.code-example pre {
  margin: 0;
  color: #fff;
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
  line-height: 1.5;
}

.stats-section {
  max-width: 800px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 3rem;
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

.recent-builds h3 {
  margin-bottom: 1.5rem;
  color: #333;
}

.empty-builds {
  text-align: center;
  padding: 3rem 2rem;
  color: #666;
}

.empty-builds p {
  margin-bottom: 1rem;
}

.build-item {
  background: white;
  border-radius: 8px;
  padding: 1rem;
  margin-bottom: 1rem;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.build-info {
  flex: 1;
}

.build-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}

.build-header h4 {
  margin: 0;
  color: #333;
}

.build-details p {
  margin: 0;
  color: #666;
  font-size: 0.9rem;
}

.build-actions {
  display: flex;
  gap: 0.5rem;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

.status-pending {
  background-color: #fef3c7;
  color: #92400e;
}

.status-processing {
  background-color: #dbeafe;
  color: #1e40af;
}

.status-completed {
  background-color: #d1fae5;
  color: #065f46;
}

.status-failed {
  background-color: #fee2e2;
  color: #991b1b;
}

.info-panel {
  position: sticky;
  top: 20px;
}

.account-overview {
  margin-top: 1rem;
}

.overview-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.overview-item:last-child {
  border-bottom: none;
}

.credits {
  font-weight: bold;
  color: #409eff;
}

.quick-actions {
  margin-top: 1rem;
}

.system-info {
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
  
  .build-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .build-actions {
    width: 100%;
    justify-content: flex-end;
  }
  
  .info-panel {
    position: static;
    margin-top: 2rem;
  }
}
</style>
