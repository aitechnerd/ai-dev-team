# MLOps Stack Profile

## When This Applies
Project has ML/AI components: model training, inference pipelines, data processing,
experiment tracking. Detected by: `torch`, `tensorflow`, `scikit-learn`, `transformers`,
`mlflow`, `wandb`, `dvc` in dependencies or imports.

## Package Manager
- Same as Python profile, plus:
- conda/mamba (environment.yml) for CUDA/GPU dependencies
- Requirements often split: `requirements.txt` + `requirements-gpu.txt`

## Data Management
- DVC: `dvc pull`, `dvc push`, `dvc repro` — tracks data + pipelines
- Data validation: Great Expectations, Pandera, or pydantic
- Feature stores: check for Feast, Tecton configs
- Large files: `.gitignore` should exclude model weights, datasets
- Convention: `data/raw/`, `data/processed/`, `data/features/`

## Experiment Tracking
- MLflow: `mlflow ui`, experiment logs in `mlruns/`
- Weights & Biases: `wandb login`, check for `wandb.init()` calls
- TensorBoard: `tensorboard --logdir runs/`
- Convention: every training run should log hyperparams, metrics, artifacts

## Model Training
- Run: typically `python train.py` or `python -m src.train`
- Config: hydra, yaml configs, or argparse — check `configs/`
- GPU: CUDA availability check, device placement
- Reproducibility: seed setting, deterministic ops, config logging
- Checkpoints: save intermediate, resume from checkpoint support

## Model Serving / Inference
- FastAPI + uvicorn for REST endpoints
- gRPC for high-throughput
- Batch inference: scripts in `scripts/` or `jobs/`
- Model loading: lazy load, warm cache on startup
- Formats: ONNX, TorchScript, SavedModel, pickle (careful with security)

## Testing
- Same as Python profile, plus:
- Model tests: check output shape, dtype, value ranges
- Data tests: schema validation, null checks, distribution drift
- Integration: end-to-end inference pipeline test
- Fixtures: small sample datasets in `tests/fixtures/`
- Convention: `tests/test_model.py`, `tests/test_pipeline.py`, `tests/test_data.py`

## Security Concerns
- Pickle deserialization: model files can execute arbitrary code on load
- Model input validation: adversarial inputs, out-of-distribution detection
- Data leakage: PII in training data, model memorization
- API rate limiting: inference endpoints can be expensive (GPU time)
- Model versioning: track which model version is serving
- Supply chain: verify model weights source (HuggingFace, model zoo)

## DevOps
- Docker: NVIDIA base images for GPU, multi-stage for smaller inference images
- CI: lint → test → train (small subset) → evaluate → build image
- GPU: separate CI runners for GPU tests, or mock
- Model registry: MLflow Model Registry, S3 artifacts, or HuggingFace Hub
- Deploy: Kubernetes + GPU nodes, SageMaker, or dedicated inference servers
- Monitoring: model performance drift, latency, throughput

## Architecture Patterns
- Training pipeline: `data_loader → preprocessor → model → trainer → evaluator`
- Inference pipeline: `input_validator → preprocessor → model → postprocessor → response`
- Config-driven: hydra or yaml configs for experiments
- Modular: separate `data/`, `models/`, `training/`, `evaluation/`, `serving/`
- Reproducible: every experiment should be re-runnable from config + data version

## Code Review Focus
- Reproducibility: seeds set? config logged? data version tracked?
- Resource leaks: GPU memory not freed, data loaders not closed
- Hardcoded paths: use config or env vars
- Magic numbers: learning rate, batch size, thresholds — should be in config
- Data leakage: test data used in training pipeline
- Evaluation: metrics calculated correctly, proper train/val/test split
