# Git Workflow for Unideal

To maintain a clean and stable codebase, we follow a specific Git branching strategy.

## Branch Structure

### 1. `main`
- **Purpose**: Stable production code.
- **Rules**:
    - This is the source for production releases.
    - No direct commits are allowed.
    - Only merges from `develop` or production hotfixes are permitted.

### 2. `develop`
- **Purpose**: Main development branch.
- **Rules**:
    - This is where all features and bug fixes are integrated.
    - Merges into `main` only when a milestone or release is ready.

### 3. `feature/*`
- **Purpose**: New features.
- **Naming**: `feature/feature-name` (e.g., `feature/chat-system`).
- **Workflow**:
    - Branch from `develop`.
    - Merge back into `develop` via Pull Request after testing.

### 4. `bugfix/*`
- **Purpose**: Fixing bugs in the development cycle.
- **Naming**: `bugfix/issue-description` (e.g., `bugfix/login-error`).
- **Workflow**:
    - Branch from `develop`.
    - Merge back into `develop` via Pull Request.

### 5. `release/*` (Optional)
- **Purpose**: Finalizing a release.
- **Naming**: `release/v1.0`.
- **Workflow**:
    - Branch from `develop`.
    - Bug fixes during final testing happen here.
    - Merge into both `main` and `develop`.

## Example Workflow

1.  **Create a feature branch**:
    ```bash
    git checkout develop
    git checkout -b feature/chat-system
    ```
2.  **Commit changes**:
    ```bash
    git add .
    git commit -m "Added chat system"
    ```
3.  **Push to remote**:
    ```bash
    git push origin feature/chat-system
    ```
4.  **Open a Pull Request** to merge into `develop`.
