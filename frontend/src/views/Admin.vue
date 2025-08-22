<template>
  <div class="admin">
    <el-container>
      <el-header class="header">
        <div class="header-content">
          <div class="logo">
            <h2>EZ-Theme 构建器 - 管理后台</h2>
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
              <el-menu-item index="/admin">管理后台</el-menu-item>
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
            <h1 class="page-title">管理后台</h1>
            <p class="page-subtitle">系统配置和用户管理</p>
          </div>

          <el-row :gutter="20">
            <el-col :span="16">
              <div class="admin-panel">
                <el-tabs v-model="activeTab">
                  <el-tab-pane label="系统配置" name="config">
                    <div class="config-section">
                      <h3>系统设置</h3>
                      <el-form 
                        ref="configForm" 
                        :model="configForm" 
                        label-width="150px"
                      >
                        <el-form-item label="每次构建费用">
                          <el-input-number 
                            v-model="configForm.price_per_build" 
                            :min="1" 
                            :max="1000"
                          />
                          <span class="form-help">积分</span>
                        </el-form-item>
                        
                        <el-form-item label="每日构建限制">
                          <el-input-number 
                            v-model="configForm.max_builds_per_day" 
                            :min="1" 
                            :max="100"
                          />
                          <span class="form-help">次</span>
                        </el-form-item>
                        
                        <el-form-item label="支付方式">
                          <el-checkbox-group v-model="configForm.payment_methods">
                            <el-checkbox label="alipay">支付宝</el-checkbox>
                            <el-checkbox label="wechat">微信支付</el-checkbox>
                            <el-checkbox label="paypal">PayPal</el-checkbox>
                          </el-checkbox-group>
                        </el-form-item>
                        
                        <el-form-item label="系统密钥">
                          <el-input v-model="configForm.license_key" placeholder="系统授权密钥" />
                        </el-form-item>
                        
                        <el-form-item>
                          <el-button type="primary" @click="saveConfig" :loading="saving">
                            保存配置
                          </el-button>
                        </el-form-item>
                      </el-form>
                    </div>
                  </el-tab-pane>

                  <el-tab-pane label="用户管理" name="users">
                    <div class="users-section">
                      <div class="users-header">
                        <h3>用户列表</h3>
                        <div class="users-actions">
                          <el-input
                            v-model="userSearch"
                            placeholder="搜索用户"
                            style="width: 200px; margin-right: 1rem;"
                            clearable
                            @input="searchUsers"
                          />
                          <el-button type="primary" @click="loadUsers" :loading="loadingUsers">
                            刷新
                          </el-button>
                        </div>
                      </div>

                      <div class="users-table" v-loading="loadingUsers">
                        <el-table :data="users" style="width: 100%">
                          <el-table-column prop="id" label="ID" width="80" />
                          <el-table-column prop="username" label="用户名" />
                          <el-table-column prop="email" label="邮箱" />
                          <el-table-column prop="credits" label="余额" width="100">
                            <template #default="scope">
                              <span class="credits">{{ scope.row.credits }}</span>
                            </template>
                          </el-table-column>
                          <el-table-column prop="is_admin" label="类型" width="100">
                            <template #default="scope">
                              <el-tag :type="scope.row.is_admin ? 'danger' : 'success'">
                                {{ scope.row.is_admin ? '管理员' : '用户' }}
                              </el-tag>
                            </template>
                          </el-table-column>
                          <el-table-column prop="created_at" label="注册时间" width="180">
                            <template #default="scope">
                              {{ formatDate(scope.row.created_at) }}
                            </template>
                          </el-table-column>
                          <el-table-column label="操作" width="280">
                            <template #default="scope">
                              <el-button 
                                size="small" 
                                type="primary"
                                @click="addCredits(scope.row)"
                              >
                                充值
                              </el-button>
                              <el-button 
                                size="small" 
                                @click="editUser(scope.row)"
                              >
                                编辑
                              </el-button>
                              <el-button 
                                size="small" 
                                type="danger" 
                                @click="deleteUser(scope.row)"
                              >
                                删除
                              </el-button>
                            </template>
                          </el-table-column>
                        </el-table>

                        <div class="pagination" v-if="userPagination.pages > 1">
                          <el-pagination
                            v-model:current-page="userCurrentPage"
                            v-model:page-size="userPageSize"
                            :page-sizes="[10, 20, 50]"
                            :total="userPagination.total"
                            layout="total, sizes, prev, pager, next, jumper"
                            @size-change="handleUserSizeChange"
                            @current-change="handleUserCurrentChange"
                          />
                        </div>
                      </div>
                    </div>

                    <!-- 充值对话框 -->
                    <el-dialog
                      v-model="creditsDialogVisible"
                      title="用户充值"
                      width="400px"
                      :close-on-click-modal="false"
                    >
                      <el-form
                        ref="creditsFormRef"
                        :model="creditsForm"
                        :rules="creditsRules"
                        label-width="100px"
                      >
                        <el-form-item label="用户名">
                          <el-input v-model="creditsForm.username" disabled />
                        </el-form-item>
                        <el-form-item label="当前余额">
                          <el-input v-model="creditsForm.currentCredits" disabled />
                        </el-form-item>
                        <el-form-item label="充值金额" prop="credits">
                          <el-input-number
                            v-model="creditsForm.credits"
                            :min="1"
                            :max="999999"
                            placeholder="请输入充值金额"
                            style="width: 100%"
                          />
                        </el-form-item>
                      </el-form>
                      <template #footer>
                        <span class="dialog-footer">
                          <el-button @click="creditsDialogVisible = false">取消</el-button>
                          <el-button type="primary" @click="confirmAddCredits" :loading="addingCredits">
                            确认充值
                          </el-button>
                        </span>
                      </template>
                    </el-dialog>
                  </el-tab-pane>

                  <el-tab-pane label="构建统计" name="stats">
                    <div class="stats-section">
                      <div class="stats-overview">
                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><User /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ systemStats.totalUsers || 0 }}</div>
                            <div class="stat-label">总用户数</div>
                          </div>
                        </div>

                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><Document /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ systemStats.totalBuilds || 0 }}</div>
                            <div class="stat-label">总构建数</div>
                          </div>
                        </div>

                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><Check /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ systemStats.completedBuilds || 0 }}</div>
                            <div class="stat-label">成功构建</div>
                          </div>
                        </div>

                        <div class="stat-card">
                          <div class="stat-icon">
                            <el-icon><Money /></el-icon>
                          </div>
                          <div class="stat-content">
                            <div class="stat-value">{{ systemStats.totalRevenue || 0 }}</div>
                            <div class="stat-label">总收入(积分)</div>
                          </div>
                        </div>
                      </div>

                      <div class="recent-activity">
                        <h3>最近活动</h3>
                        <div class="activity-list" v-loading="loadingStats">
                          <div v-if="recentActivity.length === 0 && !loadingStats" class="empty-activity">
                            <p>暂无活动记录</p>
                          </div>

                          <div v-else class="activity-item" v-for="activity in recentActivity" :key="activity.id">
                            <div class="activity-icon">
                              <el-icon v-if="activity.type === 'build'"><Document /></el-icon>
                              <el-icon v-else-if="activity.type === 'register'"><User /></el-icon>
                              <el-icon v-else><Money /></el-icon>
                            </div>
                            <div class="activity-content">
                              <div class="activity-title">{{ activity.title }}</div>
                              <div class="activity-desc">{{ activity.description }}</div>
                              <div class="activity-time">{{ formatDate(activity.created_at) }}</div>
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
                  <h3>系统信息</h3>
                  <div class="system-info">
                    <div class="info-item">
                      <span>系统版本:</span>
                      <span>v1.0.0</span>
                    </div>
                    <div class="info-item">
                      <span>Node.js版本:</span>
                      <span>{{ systemInfo.nodeVersion }}</span>
                    </div>
                    <div class="info-item">
                      <span>运行时间:</span>
                      <span>{{ systemInfo.uptime }}</span>
                    </div>
                    <div class="info-item">
                      <span>内存使用:</span>
                      <span>{{ systemInfo.memoryUsage }}</span>
                    </div>
                  </div>
                </div>

                <div class="card">
                  <h3>快速操作</h3>
                  <div class="quick-actions">
                    <el-button 
                      type="primary" 
                      @click="activeTab = 'users'"
                      style="width: 100%; margin-bottom: 1rem;"
                    >
                      用户管理
                    </el-button>
                    <el-button 
                      @click="activeTab = 'config'"
                      style="width: 100%; margin-bottom: 1rem;"
                    >
                      系统配置
                    </el-button>
                    <el-button 
                      type="success" 
                      @click="activeTab = 'stats'"
                      style="width: 100%;"
                    >
                      查看统计
                    </el-button>
                  </div>
                </div>

                <div class="card">
                  <h3>系统日志</h3>
                  <div class="system-logs">
                    <div class="log-item" v-for="log in systemLogs" :key="log.id">
                      <div class="log-level" :class="`level-${log.level}`">
                        {{ log.level.toUpperCase() }}
                      </div>
                      <div class="log-message">{{ log.message }}</div>
                      <div class="log-time">{{ formatDate(log.created_at) }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </el-col>
          </el-row>
        </div>
      </el-main>
    </el-container>

    <!-- 用户编辑弹窗 -->
    <el-dialog v-model="userDialogVisible" title="编辑用户" width="500px">
      <el-form :model="userForm" label-width="100px">
        <el-form-item label="用户名">
          <el-input v-model="userForm.username" disabled />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="userForm.email" disabled />
        </el-form-item>
        <el-form-item label="余额">
          <el-input-number v-model="userForm.credits" :min="0" />
        </el-form-item>
        <el-form-item label="用户类型">
          <el-switch
            v-model="userForm.is_admin"
            active-text="管理员"
            inactive-text="普通用户"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="userDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="saveUser" :loading="savingUser">
            保存
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'
import dayjs from 'dayjs'

export default {
  name: 'Admin',
  setup() {
    const router = useRouter()
    const route = useRoute()
    const authStore = useAuthStore()
    
    const activeIndex = ref('/admin')
    const activeTab = ref('config')
    const saving = ref(false)
    const savingUser = ref(false)
    const loadingUsers = ref(false)
    const loadingStats = ref(false)
    const userSearch = ref('')
    const userDialogVisible = ref(false)
    const creditsDialogVisible = ref(false)
    const addingCredits = ref(false)
    const users = ref([])
    const userPagination = ref({
      page: 1,
      limit: 10,
      total: 0,
      pages: 0
    })
    const userCurrentPage = ref(1)
    const userPageSize = ref(10)
    const systemStats = ref({})
    const recentActivity = ref([])
    const systemLogs = ref([])
    const systemInfo = ref({
      nodeVersion: 'v18.0.0',
      uptime: '3天 12小时',
      memoryUsage: '256MB'
    })

    const user = computed(() => authStore.user)
    const isAdmin = computed(() => authStore.isAdmin)

    const configForm = ref({
      price_per_build: 10,
      max_builds_per_day: 5,
      payment_methods: ['alipay', 'wechat'],
      license_key: ''
    })

    const userForm = ref({
      id: null,
      username: '',
      email: '',
      credits: 0,
      is_admin: false
    })

    const creditsForm = ref({
      user_id: null,
      username: '',
      currentCredits: 0,
      credits: 1
    })

    const creditsRules = {
      credits: [
        { required: true, message: '请输入充值金额', trigger: 'blur' },
        { type: 'number', min: 1, message: '充值金额必须大于0', trigger: 'blur' }
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

    const saveConfig = async () => {
      saving.value = true
      try {
        const promises = Object.entries(configForm.value).map(([key, value]) => {
          return axios.post('/api/admin/config', { key, value })
        })
        
        await Promise.all(promises)
        ElMessage.success('配置保存成功')
      } catch (error) {
        ElMessage.error('配置保存失败')
        console.error('保存配置失败:', error)
      } finally {
        saving.value = false
      }
    }

    const loadUsers = async () => {
      loadingUsers.value = true
      try {
        const response = await axios.get('/api/admin/users', {
          params: {
            page: userCurrentPage.value,
            limit: userPageSize.value,
            search: userSearch.value
          }
        })
        users.value = response.data.users || []
        userPagination.value = response.data.pagination || {
          page: 1,
          limit: 10,
          total: 0,
          pages: 0
        }
      } catch (error) {
        ElMessage.error('加载用户列表失败')
        console.error('加载用户列表失败:', error)
      } finally {
        loadingUsers.value = false
      }
    }

    const searchUsers = () => {
      userCurrentPage.value = 1
      loadUsers()
    }

    const handleUserSizeChange = (size) => {
      userPageSize.value = size
      userCurrentPage.value = 1
      loadUsers()
    }

    const handleUserCurrentChange = (page) => {
      userCurrentPage.value = page
      loadUsers()
    }

    const editUser = (user) => {
      userForm.value = { ...user }
      userDialogVisible.value = true
    }

    const saveUser = async () => {
      savingUser.value = true
      try {
        await axios.put(`/api/admin/users/${userForm.value.id}`, userForm.value)
        ElMessage.success('用户信息更新成功')
        userDialogVisible.value = false
        loadUsers()
      } catch (error) {
        ElMessage.error('更新用户信息失败')
        console.error('更新用户信息失败:', error)
      } finally {
        savingUser.value = false
      }
    }

    const deleteUser = async (user) => {
      try {
        await ElMessageBox.confirm(
          `确定要删除用户 "${user.username}" 吗？此操作不可恢复。`,
          '确认删除',
          {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'warning'
          }
        )

        await axios.delete(`/api/admin/users/${user.id}`)
        ElMessage.success('用户删除成功')
        loadUsers()
      } catch (error) {
        if (error !== 'cancel') {
          ElMessage.error('删除用户失败')
          console.error('删除用户失败:', error)
        }
      }
    }

    const addCredits = (user) => {
      creditsForm.value = {
        user_id: user.id,
        username: user.username,
        currentCredits: user.credits,
        credits: 1000
      }
      creditsDialogVisible.value = true
    }

    const confirmAddCredits = async () => {
      try {
        addingCredits.value = true
        await axios.post('/api/admin/add-credits', {
          user_id: creditsForm.value.user_id,
          credits: creditsForm.value.credits
        })
        
        ElMessage.success(`成功给用户 ${creditsForm.value.username} 充值了 ${creditsForm.value.credits} 积分`)
        creditsDialogVisible.value = false
        loadUsers() // 重新加载用户列表
      } catch (error) {
        ElMessage.error('充值失败')
        console.error('充值失败:', error)
      } finally {
        addingCredits.value = false
      }
    }

    const loadStats = async () => {
      loadingStats.value = true
      try {
        const response = await axios.get('/api/admin/stats')
        systemStats.value = response.data.stats || {}
        recentActivity.value = response.data.activity || []
      } catch (error) {
        console.error('加载统计信息失败:', error)
      } finally {
        loadingStats.value = false
      }
    }

    const loadSystemLogs = async () => {
      try {
        const response = await axios.get('/api/admin/logs')
        systemLogs.value = response.data.logs || []
      } catch (error) {
        console.error('加载系统日志失败:', error)
      }
    }

    const loadSystemConfig = async () => {
      try {
        const response = await axios.get('/api/system/config')
        const config = response.data.config
        
        configForm.value = {
          price_per_build: parseInt(config.price_per_build) || 10,
          max_builds_per_day: parseInt(config.max_builds_per_day) || 5,
          payment_methods: config.payment_methods ? config.payment_methods.split(',') : ['alipay', 'wechat'],
          license_key: config.license_key || ''
        }
      } catch (error) {
        console.error('加载系统配置失败:', error)
      }
    }

    onMounted(() => {
      loadSystemConfig()
      loadUsers()
      loadStats()
      loadSystemLogs()
    })

    return {
      activeIndex,
      activeTab,
      saving,
      savingUser,
      loadingUsers,
      loadingStats,
      userSearch,
      userDialogVisible,
      creditsDialogVisible,
      addingCredits,
      users,
      userPagination,
      userCurrentPage,
      userPageSize,
      systemStats,
      recentActivity,
      systemLogs,
      systemInfo,
      user,
      isAdmin,
      configForm,
      userForm,
      creditsForm,
      creditsRules,
      handleSelect,
      handleCommand,
      formatDate,
      saveConfig,
      loadUsers,
      searchUsers,
      handleUserSizeChange,
      handleUserCurrentChange,
      editUser,
      saveUser,
      deleteUser,
      addCredits,
      confirmAddCredits
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

.admin-panel {
  margin-bottom: 2rem;
}

.config-section h3 {
  margin-bottom: 1.5rem;
  color: #333;
}

.form-help {
  margin-left: 0.5rem;
  color: #666;
}

.users-section {
  max-width: 100%;
}

.users-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.users-header h3 {
  margin: 0;
  color: #333;
}

.users-actions {
  display: flex;
  align-items: center;
}

.credits {
  font-weight: bold;
  color: #409eff;
}

.stats-section {
  max-width: 100%;
}

.stats-overview {
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

.recent-activity h3 {
  margin-bottom: 1.5rem;
  color: #333;
}

.empty-activity {
  text-align: center;
  padding: 3rem 2rem;
  color: #666;
}

.activity-item {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 1rem;
  border-bottom: 1px solid #f0f0f0;
}

.activity-item:last-child {
  border-bottom: none;
}

.activity-icon {
  font-size: 1.5rem;
  color: #409eff;
  margin-top: 0.25rem;
}

.activity-content {
  flex: 1;
}

.activity-title {
  font-weight: 500;
  color: #333;
  margin-bottom: 0.25rem;
}

.activity-desc {
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 0.25rem;
}

.activity-time {
  color: #999;
  font-size: 0.8rem;
}

.info-panel {
  position: sticky;
  top: 20px;
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

.quick-actions {
  margin-top: 1rem;
}

.system-logs {
  margin-top: 1rem;
  max-height: 300px;
  overflow-y: auto;
}

.log-item {
  padding: 0.5rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.log-item:last-child {
  border-bottom: none;
}

.log-level {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
  margin-bottom: 0.25rem;
}

.level-info {
  background-color: #dbeafe;
  color: #1e40af;
}

.level-warning {
  background-color: #fef3c7;
  color: #92400e;
}

.level-error {
  background-color: #fee2e2;
  color: #991b1b;
}

.log-message {
  font-size: 0.875rem;
  color: #333;
  margin-bottom: 0.25rem;
}

.log-time {
  font-size: 0.75rem;
  color: #666;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 2rem;
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
  
  .users-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .stats-overview {
    grid-template-columns: 1fr;
  }
  
  .info-panel {
    position: static;
    margin-top: 2rem;
  }
}
</style>
