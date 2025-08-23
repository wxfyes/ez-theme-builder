# 使用官方Node.js 18镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    wget \
    curl

# 复制package.json文件
COPY package*.json ./
COPY frontend/package*.json ./frontend/

# 安装后端依赖
RUN npm ci --only=production

# 安装前端依赖
WORKDIR /app/frontend
RUN npm ci --only=production

# 复制源代码
WORKDIR /app
COPY . .

# 构建前端
WORKDIR /app/frontend
RUN npm run build

# 回到根目录
WORKDIR /app

# 创建必要的目录
RUN mkdir -p logs builds temp data

# 暴露端口
EXPOSE 3000

# 设置环境变量
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=512"
ENV PORT=3000

# 启动命令
CMD ["node", "server.js"]
