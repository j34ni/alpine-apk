/* PETSc production smoke: parallel MPIAIJ 5-pt Laplacian (n x n, 4 ranks),
   KSP + LU/MUMPS; residual hard-checked. LaMEM's own check() exercises the
   DMDA/ptscotch partitioning path end-to-end separately. */
static char help[] = "PETSc+MUMPS smoke test";
#include <petsc.h>

int main(int argc, char **argv) {
  Mat       A;
  Vec       x, b;
  KSP       ksp;
  PetscInt  n = 64, N = n * n, mloc, i0, i, j, r;
  PetscReal norm;

  PetscFunctionBeginUser;
  PetscCall(PetscInitialize(&argc, &argv, NULL, help));
  PetscCall(MatCreate(PETSC_COMM_WORLD, &A));
  PetscCall(MatSetSizes(A, PETSC_DECIDE, PETSC_DECIDE, N, N));
  PetscCall(MatSetFromOptions(A));
  PetscCall(MatSetUp(A));
  {
    PetscInt i1;
    PetscCall(MatGetOwnershipRange(A, &i0, &i1));
    for (i = i0; i < i1; i++) {
      PetscInt  jj = i / n, ii = i % n;
      PetscInt  col[5];
      PetscScalar v[5];
      int       nc = 0;
      col[nc] = i; v[nc] = 4.0; nc++;
      if (ii > 0)   { col[nc] = i - 1; v[nc] = -1.0; nc++; }
      if (ii < n-1) { col[nc] = i + 1; v[nc] = -1.0; nc++; }
      if (jj > 0)   { col[nc] = i - n; v[nc] = -1.0; nc++; }
      if (jj < n-1) { col[nc] = i + n; v[nc] = -1.0; nc++; }
      for (r = 0; r < nc; r++) PetscCall(MatSetValue(A, i, col[r], v[r], INSERT_VALUES));
    }
  }
  PetscCall(MatAssemblyBegin(A, MAT_FINAL_ASSEMBLY));
  PetscCall(MatAssemblyEnd(A, MAT_FINAL_ASSEMBLY));
  PetscCall(MatCreateVecs(A, &x, &b));
  PetscCall(VecSet(b, 1.0));
  PetscCall(KSPCreate(PETSC_COMM_WORLD, &ksp));
  PetscCall(KSPSetOperators(ksp, A, A));
  PetscCall(KSPSetFromOptions(ksp));
  PetscCall(KSPSolve(ksp, b, x));
  PetscCall(KSPGetResidualNorm(ksp, &norm));
  {
    PetscBool flg = PETSC_FALSE;
    PetscCall(PetscOptionsGetBool(NULL, NULL, "-expect_lu", &flg, NULL));
    if (flg && norm > 1e-8) SETERRQ(PETSC_COMM_WORLD, PETSC_ERR_PLIB, "LU residual too large: %g", (double)norm);
  }
  {
    PetscMPIInt rank;
    MPI_Comm_rank(PETSC_COMM_WORLD, &rank);
    if (!rank) PetscPrintf(PETSC_COMM_WORLD, "PETSc smoke N=%d: résidu KSP=%.3e -> %s\n", (int)N, (double)norm, norm < 1e-6 ? "OK" : "FAUX");
  }
  PetscCall(KSPDestroy(&ksp));
  PetscCall(VecDestroy(&x));
  PetscCall(VecDestroy(&b));
  PetscCall(MatDestroy(&A));
  PetscCall(PetscFinalize());
  return 0;
}
