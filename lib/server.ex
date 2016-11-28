defmodule Pooly.Server do
 use GenServer
 import Supervisor.Spec


 #####################
 # Private Functions #
 #####################

 defp prepopulate(size, sup) do
   prepopulate(size,sup,[])
 end

 defp prepopulate(size, _sup, workers) when size < 1 do
   workers
 end

 defp prepopulate(size, sup, workers) do
   prepopulate(size-1, sup, [new_worker(sup) | workers])
 end

 defp new_worker(sup) do
   {:ok, worker} = Supervisor.start_child(sup, [[]])
   worker
 end

 defmodule State do
    defstruct sup: nil, size: nil, mfa: nil
 end

 #######
 # API #
 #######

 def start_link(sup, pool_config) do
   GenServer.start_link(__MODULE__,[sup, pool_config], name: __MODULE__)
 end

 def checkout do
     GenServer.call(__MODULE__, :checkout)
 end

 ##############
 # Callbacks  #
 ##############
 def init(sup, pool_config) when is_pid(sup) do
   monitors= :ets.new(:monitors,[:private])
   init(pool_config, %State{sup: sup, monitors: monitors})
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


  def handle_call(:checkout, {from_pid, ref},%{workers:workers, monitors: monitors}= state) do
    case workers do
      [workers | rest] ->
       ref = Process.monitor(from_pid)
       true = :ets.insert(monitors,{worker, ref})
       {:reply,worker, %{state | workers : reset}
    [] ->
     {:reply, :noproc,state}
    end
   end

   def handle_cast({:checkin, worker}, %{workers: workers, monitors: monitors}=state) do
    case :ets.lookup(monitors,worker) do
      [{pid, ref}] ->
       true= Process.demonitor(ref)
       true= :ets.delete(monitors,pid)
       {:noreply, %state{ state | workers: [pid|workers]}}
      []->
       {:noreply, %state}
    end
   end

   def handle_call(:status,_from, %{workers:workers, monitors:monitors}=state ) do
     {:reply, {length(workers), :ets.info(monitors, :size)},state}
   end

 end