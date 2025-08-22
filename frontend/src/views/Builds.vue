<template>
  <div class="builds">
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
            <h1 class="page-title">构建记录</h1>
            <p class="page-subtitle">查看您的主题构建历史和下载链接</p>
          </div>

          <div class="builds-content">
            <div class="filters">
              <el-select v-model="statusFilter" placeholder="状态筛选" clearable @change="loadBuilds">
                <el-option label="全部" value="" />
                <el-option label="等待中" value="pending" />
                <el-option label="处理中" value="processing" />
                <el-option label="已完成" value="completed" />
                <el-option label="失败" value="failed" />
              </el-select>
            </div>

            <div class="builds-list" v-loading="loading">
              <div v-if="builds.length === 0 && !loading" class="empty-state">
                <el-icon size="64" color="#ccc"><Document /></el-icon>
                <h3>暂无构建记录</h3>
                <p>开始构建您的第一个主题吧！</p>
                <el-button type="primary" @click="$router.push('/builder')">
                  开始构建
                </el-button>
              </div>

              <div v-else class="build-item" v-for="build in builds" :key="build.build_id">
                <div class="build-info">
                  <div class="build-header">
                    <h4>构建 #{{ build.build_id }}</h4>
                    <span :class="['status-badge', `status-${build.status}`]">
                      {{ getStatusText(build.status) }}
                    </span>
                  </div>
                  <div class="build-details">
                    <p>创建时间: {{ formatDate(build.created_at) }}</p>
                    <p v-if="build.status_detail" class="status-detail">
                      状态详情: {{ build.status_detail }}
                    </p>
                    <p v-if="build.download_url">下载链接: {{ build.download_url }}</p>
                  </div>
                </div>
                <div class="build-actions">
                  <el-button 
                    v-if="build.status === 'completed'"
                    type="primary" 
                    @click="downloadBuild(build.build_id)"
                    :loading="downloading === build.build_id"
                  >
                    下载
                  </el-button>
                  <el-button 
                    v-if="build.status === 'pending' || build.status === 'processing'"
                    @click="checkStatus(build.build_id)"
                    :loading="checking === build.build_id"
                  >
                    检查状态
                  </el-button>
                  <el-button 
                    v-if="build.status === 'failed'"
                    type="danger"
                    @click="retryBuild(build.build_id)"
                    :loading="retrying === build.build_id"
                  >
                    重试
                  </el-button>
                </div>
              </div>
            </div>

            <div class="pagination" v-if="pagination.pages > 1">
              <el-pagination
                v-model:current-page="currentPage"
                v-model:page-size="pageSize"
                :page-sizes="[10, 20, 50]"
                :total="pagination.total"
                layout="total, sizes, prev, pager, next, jumper"
                @size-change="handleSizeChange"
                @current-change="handleCurrentChange"
              />
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
import dayjs from 'dayjs'

export default {
  name: 'Builds',
  setup() {
    const router = useRouter()
    const route = useRoute()
    const authStore = useAuthStore()
    
    const activeIndex = ref('/builds')
    const loading = ref(false)
    const builds = ref([])
    const pagination = ref({
      page: 1,
      limit: 10,
      total: 0,
      pages: 0
    })
    const currentPage = ref(1)
    const pageSize = ref(10)
    const statusFilter = ref('')
    const downloading = ref(null)
    const checking = ref(null)
    const retrying = ref(null)

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

    const getStatusText = (status) => {
      const statusMap = {
        pending: '等待中',
        processing: '处理中',
        completed: '已完成',
        failed: '失败'
      }
      return statusMap[status] || status
    }

    const formatDate = (date) => {
      return dayjs(date).format('YYYY-MM-DD HH:mm:ss')
    }

    const loadBuilds = async () => {
      loading.value = true
      try {
        const params = {
          page: currentPage.value,
          limit: pageSize.value
        }
        
        if (statusFilter.value) {
          // 注意：这里需要后端支持状态筛选，目前先不传
          // params.status = statusFilter.value
        }

        const response = await axios.get('/api/builds', { params })
        builds.value = response.data.builds
        pagination.value = response.data.pagination
      } catch (error) {
        ElMessage.error('加载构建记录失败')
        console.error('加载构建记录失败:', error)
      } finally {
        loading.value = false
      }
    }

    const downloadBuild = async (buildId) => {
      downloading.value = buildId
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
      } finally {
        downloading.value = null
      }
    }

    const checkStatus = async (buildId) => {
      checking.value = buildId
      try {
        const response = await axios.get(`/api/builds/${buildId}`)
        const build = response.data
        
        // 更新本地构建状态
        const index = builds.value.findIndex(b => b.build_id === buildId)
        if (index !== -1) {
          builds.value[index] = build
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
      } finally {
        checking.value = null
      }
    }

    const retryBuild = async (buildId) => {
      retrying.value = buildId
      try {
        const response = await axios.post(`/api/builds/${buildId}/retry`)
        ElMessage.success(response.data.message || '重试构建已开始')
        // 重新加载构建列表
        await loadBuilds()
      } catch (error) {
        const errorMessage = error.response?.data?.error || '重试失败'
        ElMessage.error(errorMessage)
        console.error('重试失败:', error)
      } finally {
        retrying.value = null
      }
    }

    const handleSizeChange = (size) => {
      pageSize.value = size
      currentPage.value = 1
      loadBuilds()
    }

    const handleCurrentChange = (page) => {
      currentPage.value = page
      loadBuilds()
    }

    onMounted(() => {
      loadBuilds()
    })

    return {
      activeIndex,
      loading,
      builds,
      pagination,
      currentPage,
      pageSize,
      statusFilter,
      downloading,
      checking,
      retrying,
      user,
      isAdmin,
      handleSelect,
      handleCommand,
      getStatusText,
      formatDate,
      loadBuilds,
      downloadBuild,
      checkStatus,
      retryBuild,
      handleSizeChange,
      handleCurrentChange
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

.builds-content {
  max-width: 800px;
  margin: 0 auto;
}

.filters {
  margin-bottom: 2rem;
  display: flex;
  gap: 1rem;
}

.builds-list {
  margin-bottom: 2rem;
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: #666;
}

.empty-state h3 {
  margin: 1rem 0;
  color: #333;
}

.empty-state p {
  margin-bottom: 2rem;
}

.build-item {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
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
  margin: 0.25rem 0;
  color: #666;
  font-size: 0.9rem;
}

.status-detail {
  color: #409eff !important;
  font-weight: 500;
  background-color: #f0f9ff;
  padding: 0.5rem;
  border-radius: 4px;
  border-left: 3px solid #409eff;
  margin: 0.5rem 0 !important;
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
  
  .build-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .build-actions {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
