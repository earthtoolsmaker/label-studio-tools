# Use the official Node.js image
FROM node:24

# Install http-server globally
RUN npm install -g http-server

# Set the working directory
WORKDIR /datasets

# Expose the port
EXPOSE 8000

# Command to run http-server
CMD ["http-server", ".", "-p", "8000", "--cors"]
