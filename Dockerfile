# Use a minimal base image
FROM node:18-alpine

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy application files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install --only=production

# Copy the rest of the application
COPY . .

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 5000

# Run the application
CMD ["node", "app.js"]
