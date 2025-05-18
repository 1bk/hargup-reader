# Use an official Node.js runtime as a parent image
FROM node:20-slim

# Install OS-level dependencies (least frequently changing)
# Group them in one RUN layer if they are installed together
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    ca-certificates \
    chromium \
    libmagic1 \
    libmagic-dev \
    libx11-6 \
    libx11-xcb1 \
    libxrandr2 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    libnss3 \
    libcups2 \
    libxss1 \
    libgconf-2-4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libpangocairo-1.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy only package.json and package-lock.json for backend
# This allows Docker to cache the npm install step if these files haven't changed
COPY backend/functions/package.json ./backend/functions/
COPY backend/functions/package-lock.json ./backend/functions/

# Install backend dependencies
# This layer will be cached if package*.json files haven't changed
RUN cd backend/functions && npm ci --unsafe-perm

# Copy the main package.json and install its dependencies (if any and if different)
# If your root package.json also has dependencies that need installing at the root level:
# COPY package.json .
# COPY package-lock.json . # if it exists
# RUN npm ci # or npm install if it's a different setup

# Now copy the rest of your application code
# This layer and subsequent layers will rebuild if any code changes
COPY backend/functions/ ./backend/functions/
COPY package.json . 
# Assuming this might contain scripts, not just deps for root

# Build the backend (compile TypeScript to JavaScript)
# This will run if code in backend/functions/ changes
RUN cd backend/functions && npm run build

# Make port 3000 available to the world outside this container
EXPOSE 3000

# Define environment variable
ENV PORT=3000

# Run the app when the container launches
CMD ["npm", "start"]
