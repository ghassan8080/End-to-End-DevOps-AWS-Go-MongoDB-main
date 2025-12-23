#!/bin/bash
# Fix local modules directory conflict

echo "🔧 Fixing local modules directory conflict..."

# Rename the local modules directory to avoid conflicts
if [ -d "modules" ]; then
    echo "Found local modules directory, renaming to modules.backup..."
    mv modules modules.backup
    echo "✅ Local modules directory renamed successfully!"
else
    echo "ℹ️  No local modules directory found"
fi

echo ""
echo "🧹 Cleaning Terraform cache..."
rm -rf .terraform .terraform.lock.hcl
echo "✅ Terraform cache cleaned!"

echo ""
echo "🚀 You can now run: terraform init -upgrade"
