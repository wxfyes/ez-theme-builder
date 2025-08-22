# 使用官方Node.js镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制package.json文件
COPY package*.json ./

# 安装后端依赖
RUN npm install

# 复制前端package.json
COPY frontend/package*.json ./frontend/

# 安装前端依赖
WORKDIR /app/frontend
RUN npm install

# 回到根目录
WORKDIR /app

# 复制所有源代码
COPY . .

# 构建前端
WORKDIR /app/frontend
RUN npm run build

# 回到根目录
WORKDIR /app

# 创建必要的目录
RUN mkdir -p builds temp logs

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["npm", "start"]
