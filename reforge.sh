#!/bin/bash
PROJECT="Venture.Tool.Framework.csproj"
PACKAGE_ID="Venture.Tool.Framework"
VERSION="1.0.1"

echo "🚀 Starting Reforge for $PACKAGE_ID..."

echo "🧹 Purging artifacts..."
dotnet build-server shutdown
rm -rf obj/ bin/ nupkg/

echo "🏗️  Building $PROJECT..."
dotnet build $PROJECT -c Release

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

echo "📦 Packaging..."
dotnet pack $PROJECT -c Release -o ./nupkg --no-build

if [ $? -eq 0 ]; then
    echo "✅ Pack successful."
    echo "🔄 Updating global tool..."
    dotnet tool uninstall -g $PACKAGE_ID
    dotnet tool install -g --add-source ./nupkg $PACKAGE_ID --version $VERSION
    echo "🎉 Reforge Complete!"
else
    echo "❌ Pack failed."
    exit 1
fi
