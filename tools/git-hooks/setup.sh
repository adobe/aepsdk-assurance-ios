#!/bin/bash
#
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# run this script to setup a git hook to run the code formatter before committing changes

GIT_HOOKS_DIR=$(dirname $0)
GIT_DIR=$(git rev-parse --git-dir)
cp $GIT_HOOKS_DIR/pre-commit $GIT_DIR/hooks
chmod +x $GIT_DIR/hooks/pre-commit
