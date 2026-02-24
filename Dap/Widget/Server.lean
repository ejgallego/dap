/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Lean
import Dap.Debugger.Core
import Dap.DAP.Capabilities

open Lean Lean.Server

namespace Dap.Server

builtin_initialize dapSessionStoreRef : IO.Ref SessionStore ←
  IO.mkRef { nextId := 1, sessions := {} }

structure InitializeParams where
  deriving Inhabited, Repr, FromJson, ToJson

abbrev InitializeResponse := DapCapabilities

structure LaunchParams where
  programInfo : ProgramInfo
  stopOnEntry : Bool := true
  breakpoints : Array Nat := #[]
  deriving Inhabited, Repr, FromJson, ToJson

abbrev LaunchResponse := Dap.LaunchResponse
abbrev BreakpointView := Dap.BreakpointView

structure SetBreakpointsParams where
  sessionId : Nat
  breakpoints : Array Nat := #[]
  deriving Inhabited, Repr, FromJson, ToJson

abbrev SetBreakpointsResponse := Dap.SetBreakpointsResponse
abbrev ThreadView := Dap.ThreadView
abbrev ThreadsResponse := Dap.ThreadsResponse

structure SessionParams where
  sessionId : Nat
  deriving Inhabited, Repr, FromJson, ToJson

abbrev ControlResponse := Dap.ControlResponse
abbrev StackFrameView := Dap.StackFrameView

structure StackTraceParams where
  sessionId : Nat
  startFrame : Nat := 0
  levels : Nat := 20
  deriving Inhabited, Repr, FromJson, ToJson

abbrev StackTraceResponse := Dap.StackTraceResponse

structure ScopesParams where
  sessionId : Nat
  frameId : Nat := 0
  deriving Inhabited, Repr, FromJson, ToJson

abbrev ScopeView := Dap.ScopeView
abbrev ScopesResponse := Dap.ScopesResponse

structure VariablesParams where
  sessionId : Nat
  variablesReference : Nat
  deriving Inhabited, Repr, FromJson, ToJson

abbrev VariableView := Dap.VariableView
abbrev VariablesResponse := Dap.VariablesResponse

structure DisconnectResponse where
  disconnected : Bool
  deriving Inhabited, Repr, FromJson, ToJson

private def mkInvalidParams (message : String) : RequestError :=
  RequestError.invalidParams message

private def runCoreResult (result : Except String α) : RequestM α :=
  match result with
  | .ok value =>
    pure value
  | .error err =>
    throw <| mkInvalidParams err

private def updateStore (store : SessionStore) : IO Unit :=
  dapSessionStoreRef.set store

private def launchFromProgramInfo
    (programInfo : ProgramInfo)
    (stopOnEntry : Bool)
    (breakpoints : Array Nat) : RequestM LaunchResponse := do
  let store ← dapSessionStoreRef.get
  let (store, response) ← runCoreResult <|
    Dap.launchFromProgramInfo store programInfo stopOnEntry breakpoints
  updateStore store
  pure response

@[server_rpc_method]
def dapInitialize (_params : InitializeParams) : RequestM (RequestTask InitializeResponse) :=
  RequestM.pureTask do
    pure dapCapabilities

@[server_rpc_method]
def dapLaunch (params : LaunchParams) : RequestM (RequestTask LaunchResponse) :=
  RequestM.pureTask do
    let info ← runCoreResult params.programInfo.validate
    launchFromProgramInfo info params.stopOnEntry params.breakpoints

@[server_rpc_method]
def dapSetBreakpoints (params : SetBreakpointsParams) :
    RequestM (RequestTask SetBreakpointsResponse) :=
  RequestM.pureTask do
    let store ← dapSessionStoreRef.get
    let (store, response) ← runCoreResult <| Dap.setBreakpoints store params.sessionId params.breakpoints
    updateStore store
    pure response

@[server_rpc_method]
def dapThreads (_params : SessionParams) : RequestM (RequestTask ThreadsResponse) :=
  RequestM.pureTask do
    pure <| Dap.threads (← dapSessionStoreRef.get)

@[server_rpc_method]
def dapNext (params : SessionParams) : RequestM (RequestTask ControlResponse) :=
  RequestM.pureTask do
    let store ← dapSessionStoreRef.get
    let (store, response) ← runCoreResult <| Dap.next store params.sessionId
    updateStore store
    pure response

@[server_rpc_method]
def dapStepIn (params : SessionParams) : RequestM (RequestTask ControlResponse) :=
  RequestM.pureTask do
    let store ← dapSessionStoreRef.get
    let (store, response) ← runCoreResult <| Dap.stepIn store params.sessionId
    updateStore store
    pure response

@[server_rpc_method]
def dapStepOut (params : SessionParams) : RequestM (RequestTask ControlResponse) :=
  RequestM.pureTask do
    let store ← dapSessionStoreRef.get
    let (store, response) ← runCoreResult <| Dap.stepOut store params.sessionId
    updateStore store
    pure response

@[server_rpc_method]
def dapStepBack (params : SessionParams) : RequestM (RequestTask ControlResponse) :=
  RequestM.pureTask do
    let store ← dapSessionStoreRef.get
    let (store, response) ← runCoreResult <| Dap.stepBack store params.sessionId
    updateStore store
    pure response

@[server_rpc_method]
def dapContinue (params : SessionParams) : RequestM (RequestTask ControlResponse) :=
  RequestM.pureTask do
    let store ← dapSessionStoreRef.get
    let (store, response) ← runCoreResult <| Dap.continueExecution store params.sessionId
    updateStore store
    pure response

@[server_rpc_method]
def dapPause (params : SessionParams) : RequestM (RequestTask ControlResponse) :=
  RequestM.pureTask do
    runCoreResult <| Dap.pause (← dapSessionStoreRef.get) params.sessionId

@[server_rpc_method]
def dapStackTrace (params : StackTraceParams) : RequestM (RequestTask StackTraceResponse) :=
  RequestM.pureTask do
    runCoreResult <| Dap.stackTrace (← dapSessionStoreRef.get) params.sessionId params.startFrame params.levels

@[server_rpc_method]
def dapScopes (params : ScopesParams) : RequestM (RequestTask ScopesResponse) :=
  RequestM.pureTask do
    runCoreResult <| Dap.scopes (← dapSessionStoreRef.get) params.sessionId params.frameId

@[server_rpc_method]
def dapVariables (params : VariablesParams) : RequestM (RequestTask VariablesResponse) :=
  RequestM.pureTask do
    runCoreResult <| Dap.variables (← dapSessionStoreRef.get) params.sessionId params.variablesReference

@[server_rpc_method]
def dapDisconnect (params : SessionParams) : RequestM (RequestTask DisconnectResponse) :=
  RequestM.pureTask do
    let (store, disconnected) := Dap.disconnect (← dapSessionStoreRef.get) params.sessionId
    updateStore store
    pure { disconnected }

end Dap.Server
