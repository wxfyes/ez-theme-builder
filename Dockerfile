# 使用Node.js 18 Alpine镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制package.json文件
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制前端package.json
COPY frontend/package*.json ./frontend/

# 安装前端依赖
RUN cd frontend && npm install

# 复制所有源代码
COPY . .

# 构建前端
RUN cd frontend && npm run build

# 准备基础构建
RUN npm run prepare-base

# 创建必要的目录
RUN mkdir -p builds temp

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["npm", "start"]
