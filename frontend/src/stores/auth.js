import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'
import Cookies from 'js-cookie'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(Cookies.get('token') || null)

  const isAuthenticated = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.is_admin || false)

  // 设置axios默认headers
  if (token.value) {
    axios.defaults.headers.common['Authorization'] = `Bearer ${token.value}`
  }

  const login = async (credentials) => {
    try {
      const response = await axios.post('/api/auth/login', credentials)
      const { token: authToken, user: userData } = response.data
      
      token.value = authToken
      user.value = userData
      
      Cookies.set('token', authToken, { expires: 7 })
      axios.defaults.headers.common['Authorization'] = `Bearer ${authToken}`
      
      return { success: true }
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.error || '登录失败' 
      }
    }
  }

  const register = async (userData) => {
    try {
      const response = await axios.post('/api/auth/register', userData)
      const { token: authToken, user: newUser } = response.data
      
      token.value = authToken
      user.value = newUser
      
      Cookies.set('token', authToken, { expires: 7 })
      axios.defaults.headers.common['Authorization'] = `Bearer ${authToken}`
      
      return { success: true }
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.error || '注册失败' 
      }
    }
  }

  const logout = () => {
    token.value = null
    user.value = null
    Cookies.remove('token')
    delete axios.defaults.headers.common['Authorization']
  }

  const fetchUserProfile = async () => {
    try {
      const response = await axios.get('/api/user/profile')
      user.value = response.data.user
      return { success: true }
    } catch (error) {
      if (error.response?.status === 401) {
        logout()
      }
      return { 
        success: false, 
        error: error.response?.data?.error || '获取用户信息失败' 
      }
    }
  }

  const updateCredits = (newCredits) => {
    if (user.value) {
      user.value.credits = newCredits
    }
  }

  return {
    user,
    token,
    isAuthenticated,
    isAdmin,
    login,
    register,
    logout,
    fetchUserProfile,
    updateCredits
  }
})
