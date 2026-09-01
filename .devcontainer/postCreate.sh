#!/usr/bin/env bash
set -e

echo "=================================================="
echo "Configuring Codespace for agriGrowthFlow"
echo "=================================================="

if [ -f requirements.txt ]; then
  echo "Installing Python requirements from requirements.txt"
  python3 -m pip install -r requirements.txt
fi

if [ -f DESCRIPTION ]; then
  echo "Installing local R package from DESCRIPTION"
  R -q -e "if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes', repos='https://cloud.r-project.org'); remotes::install_local('.')"
fi

if [ -f renv.lock ]; then
  echo "Restoring renv lockfile"
  R -q -e "if (requireNamespace('renv', quietly = TRUE)) renv::restore()"
fi

echo "Setup concluído."
