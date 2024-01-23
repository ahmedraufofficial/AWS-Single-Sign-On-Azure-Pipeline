FROM hashicorp/terraform:light

# Copy the script to the container
COPY script.sh /app/script.sh

# Make the script executable
RUN chmod +x /app/script.sh

# Run the script when the container starts
CMD ["/app/script.sh"]
