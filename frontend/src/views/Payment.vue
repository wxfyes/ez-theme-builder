<template>
  <div class="payment">
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
            <h1 class="page-title">账户充值</h1>
            <p class="page-subtitle">充值余额以继续使用构建服务</p>
          </div>

          <el-row :gutter="20">
            <el-col :span="16">
              <div class="payment-panel">
                <el-tabs v-model="activeTab">
                  <el-tab-pane label="快速充值" name="quick">
                    <div class="quick-recharge">
                      <h3>选择充值金额</h3>
                      <div class="amount-grid">
                        <div 
                          v-for="amount in presetAmounts" 
                          :key="amount"
                          :class="['amount-card', { active: selectedAmount === amount }]"
                          @click="selectedAmount = amount"
                        >
                          <div class="amount-value">¥{{ amount }}</div>
                          <div class="amount-label">获得 {{ amount }} 积分</div>
                        </div>
                        <div class="amount-card custom">
                          <el-input
                            v-model="customAmount"
                            placeholder="自定义金额"
                            type="number"
                            :min="minimumAmount"
                            @input="handleCustomAmount"
                          >
                            <template #prefix>¥</template>
                          </el-input>
                        </div>
                      </div>

                      <div class="payment-methods">
                        <h3>选择支付方式</h3>
                        <div class="method-grid">
                          <div 
                            v-for="method in paymentMethods" 
                            :key="method.value"
                            :class="['method-card', { active: selectedMethod === method.value }]"
                            @click="selectedMethod = method.value"
                          >
                            <el-icon size="24">
                              <component :is="method.icon" />
                            </el-icon>
                            <span>{{ method.label }}</span>
                            <span v-if="method.value === 'usdt'" class="usdt-note">(TRC20)</span>
                          </div>
                        </div>
                      </div>

                      <div class="recharge-summary">
                        <div class="summary-item">
                          <span>充值金额:</span>
                          <span class="amount">¥{{ finalAmount }}</span>
                        </div>
                        <div class="summary-item">
                          <span>获得积分:</span>
                          <span class="credits">{{ finalAmount }}</span>
                        </div>
                        <div class="summary-item">
                          <span>当前余额:</span>
                          <span>{{ user?.credits || 0 }}</span>
                        </div>
                        <div class="summary-item total">
                          <span>充值后余额:</span>
                          <span class="total-amount">{{ (user?.credits || 0) + finalAmount }}</span>
                        </div>
                      </div>

                      <el-button 
                        type="primary" 
                        size="large" 
                        :loading="creating"
                        :disabled="!canRecharge"
                        @click="createOrder"
                        style="width: 100%; margin-top: 2rem;"
                      >
                        立即充值
                      </el-button>
                    </div>
                  </el-tab-pane>

                  <el-tab-pane label="订单记录" name="orders">
                    <div class="orders-panel">
                      <div class="orders-header">
                        <h3>充值订单</h3>
                        <el-button @click="loadOrders" :loading="loadingOrders">
                          刷新
                        </el-button>
                      </div>

                      <div class="orders-list" v-loading="loadingOrders">
                        <div v-if="orders.length === 0 && !loadingOrders" class="empty-orders">
                          <el-icon size="64" color="#ccc"><Document /></el-icon>
                          <h3>暂无充值记录</h3>
                          <p>开始您的第一次充值吧！</p>
                        </div>

                        <div v-else class="order-item" v-for="order in orders" :key="order.order_id">
                          <div class="order-info">
                            <div class="order-header">
                              <h4>订单 #{{ order.order_id }}</h4>
                              <span :class="['status-badge', `status-${order.status}`]">
                                {{ getOrderStatusText(order.status) }}
                              </span>
                            </div>
                            <div class="order-details">
                              <p>金额: ¥{{ order.amount }}</p>
                              <p>支付方式: {{ getPaymentMethodText(order.payment_method) }}</p>
                              <p>创建时间: {{ formatDate(order.created_at) }}</p>
                            </div>
                          </div>
                          <div class="order-actions">
                            <el-button 
                              v-if="order.status === 'pending'"
                              @click="checkOrderStatus(order.order_id)"
                              :loading="checking === order.order_id"
                            >
                              检查状态
                            </el-button>
                            <el-button 
                              v-if="order.status === 'pending'"
                              type="primary"
                              @click="payOrder(order.order_id)"
                            >
                              去支付
                            </el-button>
                          </div>
                        </div>
                      </div>

                      <div class="pagination" v-if="orderPagination.pages > 1">
                        <el-pagination
                          v-model:current-page="orderCurrentPage"
                          v-model:page-size="orderPageSize"
                          :page-sizes="[10, 20, 50]"
                          :total="orderPagination.total"
                          layout="total, sizes, prev, pager, next, jumper"
                          @size-change="handleOrderSizeChange"
                          @current-change="handleOrderCurrentChange"
                        />
                      </div>
                    </div>
                  </el-tab-pane>
                </el-tabs>
              </div>
            </el-col>

            <el-col :span="8">
              <div class="info-panel">
                <div class="card">
                  <h3>账户信息</h3>
                  <div class="account-info">
                    <div class="info-item">
                      <span>用户名:</span>
                      <span>{{ user?.username }}</span>
                    </div>
                    <div class="info-item">
                      <span>邮箱:</span>
                      <span>{{ user?.email }}</span>
                    </div>
                    <div class="info-item">
                      <span>当前余额:</span>
                      <span class="credits">{{ user?.credits || 0 }}</span>
                    </div>
                    <div class="info-item">
                      <span>注册时间:</span>
                      <span>{{ formatDate(user?.created_at) }}</span>
                    </div>
                  </div>
                </div>

                <div class="card">
                  <h3>充值说明</h3>
                  <div class="recharge-info">
                    <ul>
                      <li>充值金额与获得积分比例为 1:1</li>
                      <li>每次构建主题需要消耗 {{ systemConfig.price_per_build || 10 }} 积分</li>
                      <li>支持支付宝、微信、PayPal、USDT等多种支付方式</li>
                      <li>USDT支付使用TRC20网络，当前汇率: 1 USDT = ¥{{ usdtRate }}</li>
                      <li>充值成功后积分立即到账</li>
                      <li>如有问题请联系客服</li>
                    </ul>
                  </div>
                </div>

                <div class="card">
                  <h3>API密钥</h3>
                  <div class="api-key-section">
                    <p>您可以使用API密钥进行程序化构建：</p>
                    <div class="api-key-display">
                      {{ user?.api_key }}
                    </div>
                    <el-button @click="copyApiKey" size="small">
                      复制密钥
                    </el-button>
                  </div>
                </div>
              </div>
            </el-col>
          </el-row>
        </div>
      </el-main>
    </el-container>

    <!-- 支付弹窗 -->
    <el-dialog v-model="paymentDialogVisible" title="支付订单" width="500px" center>
      <div class="payment-modal">
        <div class="order-info">
          <h4>订单 #{{ currentOrder?.order_id }}</h4>
          <p class="amount">¥{{ currentOrder?.amount }}</p>
          <p class="payment-method">支付方式: {{ getPaymentMethodText(currentOrder?.payment_method) }}</p>
        </div>
        
        <!-- USDT支付方式 -->
        <div v-if="currentOrder?.payment_method === 'usdt'" class="usdt-payment">
          <h4>USDT支付 (TRC20)</h4>
          <div class="usdt-info">
            <p><strong>支付金额:</strong> {{ currentOrder?.usdt_amount || '计算中...' }} USDT</p>
            <p><strong>收款地址:</strong></p>
            <div class="usdt-address">
              <code>{{ currentOrder?.usdt_address || '加载中...' }}</code>
              <el-button size="small" @click="copyUsdtAddress" type="primary">
                复制地址
              </el-button>
            </div>
            <p class="usdt-tip">请使用TRC20网络转账，转账完成后系统将自动确认</p>
          </div>
        </div>
        
        <!-- 其他支付方式 -->
        <div v-else class="qr-code" v-if="currentOrder?.qr_code">
          <img :src="currentOrder.qr_code" alt="支付二维码" />
          <p>请使用{{ getPaymentMethodText(currentOrder.payment_method) }}扫码支付</p>
        </div>
        
        <div class="payment-actions">
          <el-button @click="paymentDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="checkOrderStatus(currentOrder?.order_id)">
            检查支付状态
          </el-button>
        </div>
      </div>
    </el-dialog>
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
  name: 'Payment',
  setup() {
    const router = useRouter()
    const route = useRoute()
    const authStore = useAuthStore()
    
    const activeIndex = ref('/payment')
    const activeTab = ref('quick')
    const selectedAmount = ref(100)
    const customAmount = ref('')
    const selectedMethod = ref('alipay')
    const creating = ref(false)
    const loadingOrders = ref(false)
    const checking = ref(null)
    const systemConfig = ref({})
    const orders = ref([])
    const usdtRate = ref(7.2)
    const orderPagination = ref({
      page: 1,
      limit: 10,
      total: 0,
      pages: 0
    })
    const orderCurrentPage = ref(1)
    const orderPageSize = ref(10)
    const paymentDialogVisible = ref(false)
    const currentOrder = ref(null)

    const user = computed(() => authStore.user)
    const isAdmin = computed(() => authStore.isAdmin)

    // 预设充值金额
    const presetAmounts = [50, 100, 200, 300, 400, 500]

    // 支付方式
    const paymentMethods = [
      { label: '支付宝', value: 'alipay', icon: 'Money' },
      { label: '微信支付', value: 'wechat', icon: 'ChatDotRound' },
      { label: 'PayPal', value: 'paypal', icon: 'CreditCard' },
      { label: 'USDT', value: 'usdt', icon: 'Coin' }
    ]

    const minimumAmount = 1

    const finalAmount = computed(() => {
      if (customAmount.value && parseFloat(customAmount.value) >= minimumAmount) {
        return parseFloat(customAmount.value)
      }
      return selectedAmount.value
    })

    const canRecharge = computed(() => {
      return finalAmount.value >= minimumAmount && selectedMethod.value
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

    const handleCustomAmount = () => {
      if (customAmount.value) {
        selectedAmount.value = null
      }
    }

    const createOrder = async () => {
      if (!canRecharge.value) {
        ElMessage.error('请选择充值金额和支付方式')
        return
      }

      creating.value = true
      try {
        const response = await axios.post('/api/orders/create', {
          amount: finalAmount.value,
          payment_method: selectedMethod.value
        })

        currentOrder.value = response.data
        paymentDialogVisible.value = true
        
        ElMessage.success('订单创建成功，请完成支付')
      } catch (error) {
        ElMessage.error('创建订单失败')
        console.error('创建订单失败:', error)
      } finally {
        creating.value = false
      }
    }

    const checkOrderStatus = async (orderId) => {
      checking.value = orderId
      try {
        const response = await axios.get(`/api/orders/${orderId}/status`)
        const order = response.data
        
        if (order.status === 'paid') {
          ElMessage.success('支付成功！')
          paymentDialogVisible.value = false
          // 刷新用户信息
          await authStore.fetchUserProfile()
          // 刷新订单列表
          loadOrders()
        } else {
          ElMessage.info('支付尚未完成，请稍后再试')
        }
      } catch (error) {
        ElMessage.error('检查订单状态失败')
        console.error('检查订单状态失败:', error)
      } finally {
        checking.value = null
      }
    }

    const payOrder = async (orderId) => {
      try {
        // 模拟支付成功（实际项目中应该跳转到支付页面）
        await axios.post(`/api/orders/${orderId}/pay`)
        ElMessage.success('支付成功！')
        await authStore.fetchUserProfile()
        loadOrders()
      } catch (error) {
        ElMessage.error('支付失败')
        console.error('支付失败:', error)
      }
    }

    const loadOrders = async () => {
      loadingOrders.value = true
      try {
        const response = await axios.get('/api/orders', {
          params: {
            page: orderCurrentPage.value,
            limit: orderPageSize.value
          }
        })
        orders.value = response.data.orders || []
        orderPagination.value = response.data.pagination || {
          page: 1,
          limit: 10,
          total: 0,
          pages: 0
        }
      } catch (error) {
        ElMessage.error('加载订单记录失败')
        console.error('加载订单记录失败:', error)
      } finally {
        loadingOrders.value = false
      }
    }

    const handleOrderSizeChange = (size) => {
      orderPageSize.value = size
      orderCurrentPage.value = 1
      loadOrders()
    }

    const handleOrderCurrentChange = (page) => {
      orderCurrentPage.value = page
      loadOrders()
    }

    const getOrderStatusText = (status) => {
      const statusMap = {
        pending: '等待支付',
        paid: '已支付',
        failed: '支付失败',
        cancelled: '已取消'
      }
      return statusMap[status] || status
    }

    const getPaymentMethodText = (method) => {
      const methodMap = {
        alipay: '支付宝',
        wechat: '微信支付',
        paypal: 'PayPal',
        usdt: 'USDT'
      }
      return methodMap[method] || method
    }

    const copyUsdtAddress = async () => {
      try {
        const address = currentOrder.value?.usdt_address
        if (address) {
          await navigator.clipboard.writeText(address)
          ElMessage.success('USDT地址已复制到剪贴板')
        } else {
          ElMessage.error('USDT地址未加载')
        }
      } catch (error) {
        ElMessage.error('复制失败')
        console.error('复制USDT地址失败:', error)
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

    const fetchSystemConfig = async () => {
      try {
        const response = await axios.get('/api/system/config')
        systemConfig.value = response.data.config
      } catch (error) {
        console.error('获取系统配置失败:', error)
      }
    }

    const loadUsdtRate = async () => {
      try {
        const response = await axios.get('/api/usdt/rate')
        usdtRate.value = response.data.rate
      } catch (error) {
        console.error('加载USDT汇率失败:', error)
      }
    }

    onMounted(() => {
      fetchSystemConfig()
      loadUsdtRate()
      loadOrders()
    })

    return {
      activeIndex,
      activeTab,
      selectedAmount,
      customAmount,
      selectedMethod,
      creating,
      loadingOrders,
      checking,
      systemConfig,
      orders,
      orderPagination,
      orderCurrentPage,
      orderPageSize,
      paymentDialogVisible,
      currentOrder,
      user,
      isAdmin,
      presetAmounts,
      paymentMethods,
      minimumAmount,
      finalAmount,
      canRecharge,
      usdtRate,
      handleSelect,
      handleCommand,
      handleCustomAmount,
      createOrder,
      checkOrderStatus,
      payOrder,
      loadOrders,
      handleOrderSizeChange,
      handleOrderCurrentChange,
      getOrderStatusText,
      getPaymentMethodText,
      formatDate,
      copyApiKey,
      copyUsdtAddress
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

.payment-panel {
  margin-bottom: 2rem;
}

.quick-recharge h3 {
  margin-bottom: 1rem;
  color: #333;
}

.amount-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.amount-card {
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  padding: 1rem;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
}

.amount-card:hover {
  border-color: #409eff;
}

.amount-card.active {
  border-color: #409eff;
  background-color: #f0f9ff;
}

.amount-card.custom {
  cursor: default;
}

.amount-value {
  font-size: 1.5rem;
  font-weight: bold;
  color: #333;
  margin-bottom: 0.5rem;
}

.amount-label {
  font-size: 0.875rem;
  color: #666;
}

.payment-methods h3 {
  margin-bottom: 1rem;
  color: #333;
}

.method-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.method-card {
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  padding: 1rem;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.method-card:hover {
  border-color: #409eff;
}

.method-card.active {
  border-color: #409eff;
  background-color: #f0f9ff;
}

.recharge-summary {
  background: #f9f9f9;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1rem;
}

.summary-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid #e5e7eb;
}

.summary-item:last-child {
  border-bottom: none;
}

.summary-item.total {
  font-weight: bold;
  font-size: 1.1rem;
  border-top: 2px solid #409eff;
  border-bottom: none;
  margin-top: 1rem;
  padding-top: 1rem;
}

.amount, .credits, .total-amount {
  color: #409eff;
  font-weight: bold;
}

.orders-panel {
  margin-top: 1rem;
}

.orders-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.orders-header h3 {
  margin: 0;
  color: #333;
}

.empty-orders {
  text-align: center;
  padding: 4rem 2rem;
  color: #666;
}

.empty-orders h3 {
  margin: 1rem 0;
  color: #333;
}

.empty-orders p {
  margin-bottom: 2rem;
}

.order-item {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1rem;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.order-info {
  flex: 1;
}

.order-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}

.order-header h4 {
  margin: 0;
  color: #333;
}

.order-details p {
  margin: 0.25rem 0;
  color: #666;
  font-size: 0.9rem;
}

.order-actions {
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

.status-paid {
  background-color: #d1fae5;
  color: #065f46;
}

.status-failed {
  background-color: #fee2e2;
  color: #991b1b;
}

.status-cancelled {
  background-color: #f3f4f6;
  color: #374151;
}

.info-panel {
  position: sticky;
  top: 20px;
}

.account-info {
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

.recharge-info ul {
  margin: 0;
  padding-left: 1.5rem;
}

.recharge-info li {
  margin-bottom: 0.5rem;
  color: #666;
}

.api-key-section {
  margin-top: 1rem;
}

.api-key-section p {
  margin-bottom: 1rem;
  color: #666;
}

.api-key-display {
  background: #f5f5f5;
  padding: 1rem;
  border-radius: 8px;
  font-family: monospace;
  word-break: break-all;
  margin-bottom: 1rem;
  font-size: 0.875rem;
}

.payment-modal {
  text-align: center;
}

.order-info h4 {
  margin-bottom: 0.5rem;
  color: #333;
}

.order-info .amount {
  font-size: 2rem;
  font-weight: bold;
  color: #409eff;
  margin-bottom: 2rem;
}

.qr-code {
  margin: 2rem 0;
  padding: 1rem;
  background: #f9f9f9;
  border-radius: 8px;
}

.qr-code img {
  max-width: 200px;
  height: auto;
  margin-bottom: 1rem;
}

.payment-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 2rem;
}

.usdt-note {
  font-size: 0.75rem;
  color: #666;
  margin-left: 0.5rem;
}

.usdt-payment {
  margin: 2rem 0;
  padding: 1rem;
  background: #f9f9f9;
  border-radius: 8px;
  text-align: left;
}

.usdt-payment h4 {
  margin-bottom: 1rem;
  color: #333;
  text-align: center;
}

.usdt-info p {
  margin-bottom: 0.75rem;
  color: #333;
}

.usdt-address {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  padding: 0.75rem;
  background: #fff;
  border-radius: 6px;
  border: 1px solid #ddd;
}

.usdt-address code {
  flex: 1;
  font-family: monospace;
  font-size: 0.875rem;
  word-break: break-all;
  color: #333;
}

.usdt-tip {
  font-size: 0.875rem;
  color: #666;
  background: #e6f7ff;
  padding: 0.75rem;
  border-radius: 6px;
  border-left: 4px solid #409eff;
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
  
  .amount-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .method-grid {
    grid-template-columns: 1fr;
  }
  
  .order-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .order-actions {
    width: 100%;
    justify-content: flex-end;
  }
  
  .info-panel {
    position: static;
    margin-top: 2rem;
  }
}
</style>
