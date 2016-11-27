defmodule Pooly.Server do
 use GenServer
 import Supervisor.Spec

 defmodule State do
    defstruct sup: nil, size: nil, mfa: nil
 end

 #######
 # API #
 #######

 def start_link(sup, pool_config) do
   GenServer.start_link(__MODULE__,[sup, pool_config], name: __MODULE__)
 end

 ##############
 # Callbacks  #
 ##############
 def init(sup, pool_config) when is_pid(sup) do
   init(pool_config, %State{sup: sup})
 end

 #Pattern match for the MFA option, store in the server's state
 def init([{:mfa, mfa}|rest], state) do
   init(rest, %{ state| mfa: mfa})
 end

 #Pattern match for the size option, store in the server's state
 def init([{:size, size}|rest], state) do
    init(rest, %{ state| size: size})
 end


 #Ignores all other options
  def init([_|rest], state) do
    init(rest,state)
  end

  #Base case when the options list is empty
  def init([],state) do
    #start worker supervisor
    send(self, :start_worker_supervisor)
    {:ok,state}
  end


 end