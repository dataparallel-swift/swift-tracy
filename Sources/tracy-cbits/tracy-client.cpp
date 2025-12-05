// Copyright (c) 2025 The swift-tracy authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Interoperability layer to produce Tracy profiler traces from Swift
//
// This module compiles the Tracy client so that it can be integrated with the
// application. All applications then link against this library so that there is
// only ever a single instance of the client collecting instrumentation data.

#include "tracy/public/TracyClient.cpp"
