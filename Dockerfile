
# ================================
# Build image
# ================================
FROM swift

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY ./ /app

# Let Docker bind to port 8080
EXPOSE 8080

CMD ["swift", "run", "App", "serve", "--hostname", "0.0.0.0"]
