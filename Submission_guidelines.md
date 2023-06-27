# MLPerf™ Storage Benchmark Rules

## 1. Overview

MLPerf™ Storage is a benchmark suite to characterize the performance of storage systems that support machine learning workloads. 
MLPerf Storage does not require running of the actual training jobs. 

**Thus, submitters do not need to use hardware accelerators (e.g., GPUs, TPUs, and other ASICs) when running MLPerf Storage.**

Instead, our benchmark tool replaces the training on the accelerator for a single batch of data with a sleep() command. The sleep() 
interval depends on the batch size and accelerator type and has been determined through measurement on a system running the actual 
training workload. The rest of the data ingestion pipeline (data loading, caching, checkpointing) is unchanged and runs in the same 
way as when the actual training is performed.

There are two main advantages to accelerator emulation. First, MLPerf Storage allows testing different storage systems with different 
types of accelerators. To change the type of accelerator that the benchmark emulates (e.g., to switch from a system with NVIDIA A100 GPUs 
instead of V100 GPUs), it is enough to adjust the value of the sleep() parameter. The second advantage is that MLPerf Storage can put a 
high load on the storage system simply by increasing the number of emulated accelerators. This effectively allows for testing the behavior 
of the storage system in large-scale scenarios without purchasing/renting the commensurate compute infrastructure.

This version of the benchmark does not include offline and online data pre-processing. We are aware that data pre-processing is an important 
part of the ML data pipeline and we will include it in a future version of the benchmark.

This benchmark attempts to balance two goals. First, we aim for comparability between benchmark submissions to enable decision making by 
the AI/ML Community. Second, we aim for flexibility to enable experimentation and to show off unique storage system features that will 
benefit the AI/ML Community. To that end we have defined two classes of submissions: CLOSED and OPEN. 
The MLPerf name and logo are trademarks of the MLCommons® Association ("MLCommons"). In order to refer to a result using the MLPerf name, 
the result must conform to the letter and spirit of the rules specified in this document. MLCommons reserves the right to solely determine 
if a use of its name or logos is acceptable.

### Timeline

| Date | Description |
| --- | ----------- |
|  May 19, 2023 | Freeze rules (Sections 1 – 6) & Freeze benchmark code. |
| June 19, 2023 | Open benchmark for submissions & Freeze rules (Sections 7–9). |
|August 4, 2023 |**Submissions due.**|
|Aug 4, 2023 – Sept 1, 2023 | Review period. Deadline to submit issues with competitors’ submissions: August 18, 2023|
|September 13, 2023|**Benchmark competition results are published.**|

### Benchmarks

The benchmark suite internally uses DLIO, a deep learning I/O benchmark code for simulating the I/O patterns of actual deep learning workloads. 
The benchmark suite provides specific DLIO configurations in order to simulate the I/O patterns of selected workloads listed in Table 1. 
The I/O patterns for each MLPerf Storage benchmark correspond to the I/O patterns of the reference implementations of the MLPerf Training benchmarks 
(i.e., the I/O generated by our tool for U-Net3D closely follows the I/O generated by actually running the U-Net3D training workload). The benchmark 
suite also uses DLIO to generate synthetic datasets which show the same I/O load as the actual datasets listed in Table 1. 

|Area | Problem | Model | ML Framework | Dataset seed |
| --- | -------- | ---- |------------- |-------------- |
| Vision | Image segmentation (medical) | 3D U-Net | PyTorch | KiTS 19 |
| Language | NLP | BERT | Tensorflow |Wikipedia |

- Benchmark start point: The dataset is in shared persistent storage. 
- Benchmark end point: The measurement ends after a predetermined number of epochs. The end point for the data is host DRAM. Transfering  data into
  the accelerator memory is not included in this benchmark. 
- Specific information on the workloads and dataset content can be found [here](https://github.com/mlcommons/storage/tree/main/storage-conf/workload).

### Definitions

The following definitions are used throughout this document:

- A **sample** is the unit of data on which training is run, e.g., an image, or a sentence.
- **Accelerator utilization (AU)** is defined as the percentage of time taken by the simulated accelerators, relative to the total benchmark running
  time. Higher is better. 
- A **division** is a set of rules for implementing benchmarks from a suite to produce a class of comparable results. MLPerf Storage allows CLOSED
  and OPEN divisions, detailed in Section 6.
- **DLIO** ([code link](https://github.com/argonne-lcf/dlio_benchmark), [paper link](https://ieeexplore.ieee.org/document/9499416)) is a benchmarking
  tool for deep learning applications. DLIO is the backend for running the MLPerf Storage benchmark by providing specific configuration in order to
  emulate the I/O pattern for selected workloads listed in Table 1.  MLPerf Storage provides a wrapper script to launch DLIO. There is no need to know
  the internals of DLIO to do a CLOSED submission, as the scripts provided by MLPerf Storage will suffice. However, for OPEN submissions changes to
  the DLIO code might be required (e.g., to add custom data loaders). 
- **Dataset content** refers to the data and the total capacity of the data, not the format of how the data is stored. Specific information on dataset
  content can be found [here](https://github.com/mlcommons/storage/tree/main/storage-conf/workload). 
- **Dataset format** refers to the format in which the training data is stored (e.g., npz, hdf5, csv, png, tfrecord, etc.), not the content or total
  capacity of the dataset.
*NOTE: we plan to add support for Object storage in a future version of the benchmark, so OPEN submissions that include benchmark application changes
and a description of how the original MLPerf Training benchmark dataset was mapped into Objects will be appreciated.*
- A **system** consists of a defined set of hardware resources such as number of hosts, processors per host (excluding accelerators), host memory
  (excluding accelerator memory), disks, and interconnect. It also includes specific versions of all software such as operating systems, compilers,
  libraries, and drivers that significantly influences the running time of a benchmark, excluding the ML framework.
- A **host node** refers to a machine on which the MLPerf Storage benchmark code is running.
- An **ML framework** is a specific version of a software library or set of related libraries for training ML models using a system. Examples include
  specific versions of Caffe2, MXNet, PaddlePaddle, PyTorch, or TensorFlow.
- A **benchmark** is an abstract problem that can be solved using ML by training a model based on a specific dataset or simulation environment to a
  target quality level.
- A **reference implementation** is a specific implementation of a benchmark provided by the MLPerf organization.
- A **benchmark implementation** is an implementation of a benchmark in a particular framework by a user under the rules of a specific division.
- A **run** is a complete execution of a benchmark implementation on a system.
- A **benchmark result** is the mean of 5 run results, executed consecutively. The dataset is generated only once for the 5 runs. The 5 runs must be done on the same machine.

### Performance Metrics

The benchmark performance metric is **samples per second, subject to a minimum accelerator utilization (AU) of 90%**. Higher samples per second is better. 

To pass a benchmark run, AU should be 90% or higher. AU is computed as follows. Then AU is computed as follows:

```
AU (percentage) = (total_compute_time/total_benchmark_running_time) * 100
```

The total compute time can be derived from the batch size, total dataset size, number of simulated accelerators, and sleep time: 
```
total_compute_time = (records/file * total_files)/simulated_accelerators/batch_size * sleep_time
```
*NOTE: The sleep time has been determined by running the actual MLPerf training workloads including the compute step on real hardware and is dependent 
on the accelerator type. In this preview package we include sleep times for **NVIDIA V100 GPUs**, as measured in an **NVIDIA DGX-1 system**. We plan on expanding 
the measurements to different accelerator types in future releases.*

### Benchmark Code

The MLPerf Storage working group provides a benchmark implementation which includes:
- Scripts to determine the minimum dataset size required for your system, for a given benchmark.
- Scripts for data generation using DLIO.
- Benchmark tool, based on DLIO, with reference implementation of the benchmarks.
- Scripts for running the benchmark on one host (additional setup is required if you are running a multi-host benchmark – see Section 5). 
- Scripts for generating the results report (additional scripting and setup may be required if you are running a multi-host benchmark – see Section 5).

More details on installation and running the benchmark can be found [here](https://github.com/mlcommons/storage). 

## 2. General Rules

The following apply to all results submitted for this benchmark.

**2.1 Strive to be fair**

Benchmarking should be conducted to measure the framework and storage system performance as fairly as possible. Ethics and reputation matter.

**2.2 System and framework must be available**

- **Available Systems.** If you are measuring the performance of a publicly available and widely-used system or framework, you must use publicly available and
  widely-used versions of the system or framework. This class of systems will be called Available Systems, and availability here means the system is a publicly
  available commercial storage system. If you are measuring the performance of a system that is not available at the time of the benchmark results submission,
  the system must become commercially available within **6 months** from results publication. Otherwise, the results for that submission will be retracted from the
  MLCommons results dashboard.
- **RDI Systems.** If you are measuring the performance of an experimental framework or system, you must make the system and framework you use available upon
  demand for replication by MLCommons. This class of systems will be called RDI (research, development, internal).

**2.3 Non-determinism**

The data generator in DLIO uses a fixed random seed that must not be changed, to ensure that all submissions are working with the same dataset. Random number
generators may be seeded from the following sources:
- Clock
- System source of randomness, e.g. /dev/random or /dev/urandom
- Another random number generator initialized with an allowed seed
Random number generators may be initialized repeatedly in multiple processes or threads. For a single run, the same seed may be shared across multiple processes or threads.

**2.4 Result rounding**

Public results should be rounded normally, to two decimal places.

**2.5 Stable storage must be used**

The MLPerf Storage benchmark will create the dataset on the storage system, in the desired dataset format, before the start of the benchmark run.  The data must 
reside on stable storage before the actual benchmark testing can run.

**2.6 Caching**

Under all circumstances, caching of training data on the host node(s) running MLPerf Storage before the benchmark begins is DISALLOWED. Caches must be cleared 
between two consecutive benchmark runs.

**2.7 Replicability is mandatory**

Results that cannot be replicated are not valid results. Replicated results should be within 5% within 5 tries.

## 3. Datasets
MLPerf Storage uses DLIO to generate synthetic data. Instructions on how to generate the datasets for each benchmark are available [here](https://github.com/mlcommons/storage). 
The datasets are generated following the sample size distribution and structure of the dataset seeds (see Table 1) for each of the benchmarks. 

**Minimum dataset size.** The MLPerf Storage benchmark script must be used to run the benchmarks the minimum dataset size for each benchmark, given a number of simulated accelerators
and the size of the host memory in GB. The minimum dataset size computation is as follows.

- Calculate required minimum samples given number of steps per epoch:

   ```min_samples_steps_per_epoch = num_steps_per_epoch * batch_size * num_accelerators```
- Calculate required minimum samples given host memory to eliminate client-side caching effects; (*NB: HOST_MEMORY_MULTIPLIER = 5*):

  ```min_samples_host_memory=host_memory_in_gb * HOST_MEMORY_MULTIPLIER * 1024 * 1024 * 1024 / record_length```
- Ensure we meet both constraints:

  ```min_samples = max(min_samples_steps_per_epoch, min_samples_host_memory)```
- Calculate minimum files to generate:

  ```min_total_files= min_samples / num_samples_per_file```

  ```min_files_size = min_samples * record_length / 1024 / 1024 / 1024```

A minimum of ```min_total_files``` files are required which will consume ```min_files_size``` GB of storage.

**Running benchmark  on a subset of a larger dataset.** We support running benchmarks  on a subset of the dataset. One can generate a large dataset while running the benchmark 
only on a subset of the dataset by setting num_files_train or num_files_eval smaller than the number of files available in the dataset folder. However, if the dataset is stored 
in multiple subfolders, the subset will be evenly selected from all the subfolders. In this case, num_subfolders_train and num_subfolders_eval need to be equal to the actual 
number of subfolders inside the dataset folder.

## 4. Single-host Submissions
Submitters can add load to the storage system in two ways: (1) increase the number of simulated accelerators inside one host node (i.e., one machine), and (2) increase the number 
of host nodes connected to the storage system. Note that for a valid multi-host submission the number of simulated accelerators run by each host node must be identical.

For single-host submissions, increase the number of simulated accelerators by changing the ```--num-accelerators parameter``` in the benchmark.sh script. Note that the benchmarking tool 
requires approximately 0.5GB of host memory per simulated accelerator.

For single-host submissions, CLOSED and OPEN division results must include benchmark runs for:
1. One simulated accelerator AND
2. The maximum simulated accelerators that can be run on ONE HOST NODE, in ONE MLPerf Storage job, without going below the 90% accelerator utilization threshold.

## 5. Multi-host Submissions

This setup simulates multiple independent benchmarks of the same type (i.e., multiple BERT workloads, or multiple Unet-3D workloads; It is not acceptable for a submission to 
run BERT on X host nodes and Unet-3D on Y host nodes), each working on their separate datasets, where all the datasets are initially stored in the same shared storage system. 
In particular, *this setup does not support distributed training of a single benchmark (i.e., multiple hosts training a single benchmark on a shared dataset).*

Submitters must respect the following for multi-host submissions:
- Each host node must run a single MLPerf Storage job, run through a single benchmark.sh script.
- All the data must be accessible to all the hosts. 
- The checkpoint location must reside in the same storage system that stores the dataset.
- All nodes must be identical (same core count/model, same amount of host memory, same OS etc).
- All benchmarks.sh parameters must be identical for all the hosts. 
- **The number of simulated accelerators in each host node must be identical.**
- Submitters must ensure that the benchmark on all the hosts starts approximately at the same time, i.e.,for one run, the benchmark on all hosts needs to start within a 10s interval.

For multi-host submissions, CLOSED and OPEN division results must include benchmark runs for:
1. One simulated accelerator, **AND**
2. The maximum simulated accelerators that can be run on ONE HOST NODE, in ONE MLPerf Storage job, without going below the 90% accelerator utilization threshold, **AND**
3. The maximum simulated accelerators that can be run in the multi-host setup, with ONE MLPerf Storage job per host node, without going below the 90% accelerator utilization
   threshold. Each host node must run the same number of simulated accelerators for the submission to be valid.

*Note:  The maximum number of simulated accelerators in point 2) and 3) are likely to differ. For example, the maximum number of simulated accelerators that Storage System X 
can support for a single host node Y is likely to differ from the maximum number of simulated accelerators **per host node** that Storage System X can support when running N hosts 
nodes identical to Y.*

## 6. CLOSED and OPEN Divisions

### CLOSED: virtually all changes are disallowed

CLOSED represents a level playing field where all results are **comparable** across submissions. CLOSED explicitly forfeits flexibility in order to enable easy comparability. 

In order to accomplish that, the optimizations and customizations to the storage system configuration or AI/ML algorithms that might typically be applied during benchmarking 
or even during production use must be disallowed.  

For CLOSED submissions of this benchmark, the MLPerf Storage codebase takes the place of the AI/ML algorithms, and therefore cannot be changed. 

A small number of parameters can be configured, listed in the table below.

| Parameter | Description | Default|
| --------- | ------------|---------|
|**Dataset parameters**|||
|dataset.num_files_train | Number of files for the training set | -|
|dataset.num_subfolders_train | Number of subfolders that the training set is stored | 0 |
| dataset.data_folder | The path where dataset is stored | - |
|**Reader parameters**|||
|reader.read_threads | Number of threads to load the data | -|
|reader.computation_threads | Number of threads to preprocess the data(only for bert)| - |
|**Checkpoint parameters**|||
|checkpoint.checkpoint_folder | The folder to save the checkpoints| -|
|**Storage parameters**|||
|storage.storage_root | The storage root directory | ./ |
| storage.storage_type | The storage type | local_fs |

CLOSED division benchmarks must be referred to using the benchmark name plus the term CLOSED, e.g. “The system was able to support N ACME X100 accelerators running a CLOSED 
division 3D U-Net workload at only 12% less than optimal performance.”

Since the benchmark supports both PyTorch and TensorFlow data formats, and those formats apply such different loads to the storage system, cross-format comparisons are not 
appropriate, even with CLOSED submissions. Thus, only comparisons between CLOSED PyTorch runs, or comparisons between CLOSED TensorFlow runs, are comparable. As new data 
formats like PyTorch and TensorFlow are added to the benchmark that categorization will grow.

### OPEN: changes are allowed but must be disclosed

OPEN allows more **flexibility** to tune and change both the benchmark and the storage system configuration to show off new approaches or new features that will benefit 
the AI/ML Community. OPEN explicitly forfeits comparability to allow showcasing innovation. 

The essence of OPEN division results is that for a given benchmark area, they are “best case” results if optimizations and customizations are allowed. The submitter has 
the opportunity to show the performance of the storage system if an arbitrary, but documented, set of changes are made to the data storage environment.  

Changes to DLIO are allowed in OPEN division submissions.  Any changes to DLIO code or command line options must be disclosed. 

In addition to what can be changed in the CLOSED submission, the following parameters can be changed in the benchmark.sh script:

|Parameter | Description | Default |
|----------|-------------|---------|
|framework|The machine learning framework| Pytorch for 3D U-Net, Tensorflow for BERT.|
|**Dataset parameters**|||
|dataset.format|Format of the dataset| .npz for 3D U-Net and tfrecord for BERT.|
|dataset.num_samples_per_file|Changing this parameter is supported only with Tensorflow, using tfrecord datasets. Currently, the benchmark code only supports num_samples_per_file = 1 for Pytorch data loader. To support other values,  the dataloader needs to be adjusted. | For 3D U-Net: 1 ; For Bert: 313532 |
|**Reader parameters**|||
|reader.data_loader | Supported options: Tensorflow or PyTorch. OPEN submissions can have custom data loaders. If a new dataloader is added, or an existing data loader is changed, the DLIO code will need to be modified. | PyTorch (Torch Data Loader) for 3D U-Net, and Tensorflow (tf.data) for BERT.|
|reader.transfer_size | An int64 scalar representing the number of bytes in the read buffer. (only supported for Tensorflow) |For BERT: 262144 |

**Benchmark submissions in the OPEN division still need to be run through the benchmark.sh. The .yaml files cannot be changed. The parameters can be changed only via the 
command line.**

OPEN division benchmarks must be referred to using the benchmark name plus the term OPEN , e.g. “The system was able to support N ACME X100 accelerators running an OPEN 
division 3D U-Net workload at only 12% less than optimal performance.”

## 7. Submission

A **successful run result** consists of a mean samples/second measurement (```train_throughput_mean_samples_per_second```) for a complete benchmark run that achieves 
mean accelerator utilization (train_au_mean_percentage) **larger than 90%.**

**Submissions are made via this link: [https://mlperf.netlify.app/](https://mlperf.netlify.app/)**

**Before submitting it is mandatory to complete the [Intention to submit form](https://docs.google.com/forms/d/e/1FAIpQLSfVgc1x1moe8LqkEprf0OzCYuefufIQkh2wlSWVDXenmwGkGw/viewform), as this is how we will collect email addresses to contact submitters.**

### What to submit - CLOSED submissions

A complete submission for one benchmark (3D-Unet and/or BERT) contains 3 folders:
1. **results** folder, containing, for each system:
  - The entire output folder generated by running MLPerf Storage. 
  - Final submission JSON summary file ```mlperf_storage_report.json```. The JSON file must be generated using ```./benchmark.sh``` reportgen script.
  - Structure the output as shown in this [example](https://github.com/johnugeorge/mlperf-storage-sample-results).
     
2. **systems** folder, containing:
  - ```<system-name>.json```
  - ```<system-name>.pdf```
  - For system naming examples look [here](https://github.com/mlcommons/inference_results_v3.0/tree/main/closed)
    
3. **code** folder, containing:
  - Source code of the benchmark implementation. The submission source code and logs must be made available to other submitters for auditing purposes during the review period.

**An example of a submission structure can be found [here](https://github.com/johnugeorge/mlperf_storage_sample_submission/tree/main)**

### What to submit - OPEN submissions
- Everything that is required for a CLOSED submission, following the same structure.
- Additional source code used for the OPEN Submission benchmark implementations must be available under a license that permits MLCommon to use the implementation for benchmarking. 

### Directory Structure
```
root_folder (or any name you prefer)
├── Closed
│ 	└──<submitter_org>
│		├── code
│		├── results
│		│	├──system-name-1
│		│	│	├── unet3d
│		│	│	│	└── ..
│		│	│	└── bert	
│		│	└──system-name-2
│		│		├── unet3d
│		│		│	└── ..
│		│		└── bert			
│		└── systems
│			system-name-1.json
│			system-name-1.pdf
│			system-name-2.json
│			system-name-2.pdf
│
└── Open
 	└──<submitter_org>
		├── code
		├── results
		│	├──system-name-1
		│	│	├── unet3d
		│	│	│	└── ..
		│	│	└── bert	
		│	└──system-name-2
		│		├── unet3d
		│		│	└── ..
		│		└── bert			
		└── systems
			system-name-1.json
			system-name-1.pdf
			system-name-2.json
			system-name-2.pdf
```

### System description format

The purpose of the system description is to provide sufficient detail on the system to enable full reproduction by a third party. 

Every submission must contain a ```<system-name>.json``` file and a ```<system-name>.pdf```. 

Note that, during the review period, submitters may be asked to include additional details in the JSON and pdf to enable reproducibility by a third party.

**System description JSON**

We recommend the following structure for the Systems JSON. Since this is the first submission, we encourage submitters to include any other fields that are 
relevant to enable a third party to reproduce the submission results.

```
"host_node": {
  "node_count": //2
  "OS_version": //Ubuntu22.04
  "memory_capacity_gigabytes": //128
  "cpu_core_count": // 36
  "cpu_socket_count": // 2
  "cpu_frequency_gigahertz": // 3
  "cpu_model": // XeonE5-2680
},

"storage_system": {
  “category”: //research, commercial
  “software_specification”: //Lustre 2.12
  “type”: //NFS, S3, Local drive, Lustre, GPFS
  “total_read_bandwidth_sequential_GB_per_sec”: //650
  “total_write_bandwidth_sequential_GB_per_sec”: //650
  “total_storage_capacity_TB”: 

  "hardware": [
    {
    "Count": //4
    “Vendor”: //Dell
    "type": //SSD, HDD
    “Model”: //NX8170G8, 
    “protocol”: //NVMe
    "Disk_capacity_gigabytes": //1000
    },
  ],

  //other system-specific optional fields (free-form).
},

"host_to_storage_interconnect": [
{
  “interconnect_type”: //InfiniBand, Ethernet, PCIe
  "model": //NVIDIA-spectrum-3-SN400
  "link_speed_gigabits_per_second": //400	
  "rdma_enabled": //yes, no
},]

```

**System description PDF**

The goal of the pdf is to complement the JSON file, providing additional detail on the system to enable full reproduction by a third party. We encourage submitters 
to add details that are more easily captured by diagrams and text description, rather than a JSON.

The following recommended structure of systems.pdf provides a starting point and is optional. Submitters are free to adjust this structure as they see fit.

If the submission is for a commercial system, it is enough to provide a pdf of the spec document.

If it is a system that does not have a spec document (e.g., a research system, HPC etc), the document can contain (all these are optional):
  - High-level system diagram e.g., showing the host node(s), storage system main components, and network topology used when connecting everything (e.g., spine-and-leaf, butterfly, etc.).
  - Additional text description of the system, if the information is not captured in the JSON, e.g., the storage system’s components (make and model, optional features,
    capabilities, etc) and all configuration settings that are relevant to ML/AI benchmarks.
  - If the make/model doesn’t specify all the components of the hardware platform it is running on, eg: it’s an Software-Defined-Storage product, then those should be included here
    (just like the client component list). We recommended the following three categories for the text description:
1. Software,
2. Hardware, and
3. Settings. 

## 8. Review

### Visibility of results and code during review

During the review process, only certain groups are allowed to inspect results and code.

|Group | Can Inspect|
| -----|-------------|
|Review committee | All results, all code
| Submitters | All results, all code
| Public | No results, no code

### Filing objections

Submitters must officially file objections to other submitter’s code by creating a GitHub issue prior to the “Filing objections” deadline that cites the offending lines, the rules section 
violated, and, if pertinent, corresponding lines of the reference implementation that are not equivalent. Each submitter must file objections with a “by \<org\>” tag and a “against \<org\>” 
tag. Multiple organizations may append their “by \<org\>” to an existing objection if desired. If an objector comes to believe the objection is in error they may remove their “by \<org\>” 
tag. All objections with no “by \<org\>” tags at the end of the filing deadline will be closed. Submitters should file an objection, then discuss with the submitter to verify if the 
objection is correct. Following filing of an issue but before resolution, both objecting submitter and owning submitter may add comments to help the review committee understand the 
problem. If the owning submitter acknowledges the problem, they may append the “fix_required” tag and begin to fix the issue.

### Resolving objections

The review committee will review each objection, and either establish consensus or vote. If the committee votes to support an objection, it will provide some basic guidance on an acceptable fix 
and append the “fix_required” tag. If the committee votes against an objection, it will close the issue.

### Fixing objections

Code should be updated via a pull request prior to the “fixing objections” deadline. Following submission of all fixes, the objecting submitter should confirm that the objection has been addressed 
with the objector(s) and ask them to remove their “by <org> tags. If the objector is not satisfied by the fix, then the review committee will decide the issue at its final review meeting. The review 
committee may vote to accept a fix and close the issue, or reject a fix and request the submission be moved to open or withdrawn.

### Withdrawing results / changing division

Anytime up until the final human readable deadline (typically within 2-3 business days before the press call), an entry may be withdrawn by amending the pull request. 
Alternatively, an entry may be voluntarily moved from the closed division to the open division.

## 9. Roadmap for future MLPerf Storage releases

This is the first time we open the benchmark for submissions and we are very interested in your feedback. Please contact oana.balmau@mcgill.ca with any suggestions.

Our working group aims to add the following features in a future version of the benchmark:
- We plan to add support for the “data pre-processing” phase of AI/ML workload as we are aware that this is a significant load on a storage system and is not well represented by existing AI/ML benchmarks. 
- Add support for other types of storage systems (e.g., Object Stores) in the CLOSED division.
- Expand the number of workloads in the benchmark suite e.g., add a recommender system workload (DLRMv2), a large language model (GPT3), and a diffusion model (Stable Diffusion).
- Add support for PyTorch and Tensorflow in the CLOSED division for all workloads.
- The current benchmark only includes sleep() values for NVIDIA V100 GPUs. We plan to add support for multiple types of accelerators.
- We plan to add support for benchmarking a storage system while running more than one MLPerf Storage benchmark at the same time (ie: more than one Training job type, such as 3DUnet and Recommender at the same time), but the current version requires that a submission only include one such job type per submission. 
- We also plan to add support for distributed training of a single AI/ML job, distributed across several compute nodes.
