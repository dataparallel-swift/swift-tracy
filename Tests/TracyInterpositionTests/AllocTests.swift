// Copyright (c) 2026 The swift-tracy authors. All rights reserved.
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

// Tests that the Tracy malloc interposition layer is transparent — i.e. all
// allocation functions still behave correctly after interception.
//
// These tests do NOT verify that Tracy records the allocations (that requires
// a running Tracy server and is validated manually via the demo executable).
// They DO validate that the interposition chain is intact: a broken interpose
// (e.g. infinite recursion, wrong pointer returned) will fail these tests.
//
// Run with: SWIFT_TRACY_ENABLE=true swift test

// The idiomatic replacement for force unwrapping here is `try #require(...)`,
// which records the failure and stops the test if nil, without crashing.
// However, these are allocator correctness tests -- if malloc returns nil the
// process is effectively out of memory and a hard crash is the right signal.
// #require adds noise for a nil branch that is effectively unreachable in any
// realistic test environment.
//
// swiftlint:disable force_unwrapping

import Testing
import TracyC

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

@Suite("Malloc interposition")
struct AllocTests {

    // MARK: malloc

    @Test func mallocReturnsUsableMemory() {
        let size = 256
        let ptr = malloc(size)!
        // Write and read back a pattern to verify the memory is usable.
        memset(ptr, 0xab, size)
        let bytes = ptr.bindMemory(to: UInt8.self, capacity: size)
        for i in 0 ..< size {
            #expect(bytes[i] == 0xab)
        }
        free(ptr)
    }

    @Test func mallocZeroSizeDoesNotCrash() {
        // malloc(0) is implementation-defined but must not crash.
        let ptr = malloc(0)
        if let ptr {
            free(ptr)
        }
    }

    // MARK: calloc

    @Test func callocReturnsZeroedMemory() {
        let count = 32
        let size = 8
        let ptr = calloc(count, size)!
        let bytes = ptr.bindMemory(to: UInt8.self, capacity: count * size)
        for i in 0 ..< (count * size) {
            #expect(bytes[i] == 0, "calloc byte \(i) not zero")
        }
        free(ptr)
    }

    // MARK: realloc

    @Test func reallocGrows() {
        let ptr = malloc(64)!
        memset(ptr, 0xcd, 64)
        let newPtr = realloc(ptr, 128)!
        // First 64 bytes must be preserved.
        let bytes = newPtr.bindMemory(to: UInt8.self, capacity: 128)
        for i in 0 ..< 64 {
            #expect(bytes[i] == 0xcd, "realloc byte \(i) not preserved")
        }
        free(newPtr)
    }

    @Test func reallocShrinks() {
        let ptr = malloc(256)!
        memset(ptr, 0xef, 256)
        let newPtr = realloc(ptr, 64)!
        let bytes = newPtr.bindMemory(to: UInt8.self, capacity: 64)
        for i in 0 ..< 64 {
            #expect(bytes[i] == 0xef, "realloc shrink byte \(i) not preserved")
        }
        free(newPtr)
    }

    @Test func reallocNullActsLikeMalloc() {
        let ptr = realloc(nil, 128)!
        memset(ptr, 0, 128)
        free(ptr)
    }

    // MARK: free

    @Test func freeNilDoesNotCrash() {
        free(nil)
    }

    // MARK: posix_memalign

    @Test func posixMemalignAligns() {
        let alignment = 64
        let size = 256
        var ptr: UnsafeMutableRawPointer? = nil
        let result = posix_memalign(&ptr, alignment, size)
        #expect(result == 0)
        let addr = Int(bitPattern: ptr)
        #expect(addr % alignment == 0, "posix_memalign result not \(alignment)-byte aligned")
        memset(ptr!, 0, size)
        free(ptr!)
    }

    // MARK: aligned_alloc

    @Test func alignedAllocAligns() {
        let alignment = 64
        // aligned_alloc requires size to be a multiple of alignment.
        let size = 128
        let ptr = aligned_alloc(alignment, size)!
        let addr = Int(bitPattern: ptr)
        #expect(addr % alignment == 0, "aligned_alloc result not \(alignment)-byte aligned")
        memset(ptr, 0, size)
        free(ptr)
    }
}

// swiftlint:enable force_unwrapping
