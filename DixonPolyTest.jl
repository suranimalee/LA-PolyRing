function randpoly(P::PolyRing{T},U::AbstractArray) where T 
  d=rand(U)
  R=base_ring(P)
  x=gen(P)
  a = P(0)
  for i=0:d
     setcoeff!(a, d-i, rand(R))
  end
  return a
end



function rand_mat(A::MatSpace{T}, U::AbstractArray) where T
  P=base_ring(A)
  A=A(0)
  for i=1:nrows(A)
    for j=1:ncols(A)
     A[i,j]=randpoly(P, U)
    end
  end
  return A
end 


function array_mat(A::MatElem{T}) where T
   a = []
   for i=1:nrows(A)
     for j=1:ncols(A)
	push!(a, A[i,j])
     end
   end
  return a
end



function rand_pol(P::PolyRing{T},U::AbstractArray) where T 
  d=rand(U)
  R=base_ring(P)
  x=gen(P)
  a = P(0)
  for i=1:d
     setcoeff!(a, d-i, rand(R))
  end
  setcoeff!(a, d, R(1))  
  return a
end


function rand_irreducible_pol(P::PolyRing{T},U::AbstractArray) where T 
  d = rand(U)
  R = base_ring(P)
  x = gen(P)
  a = P(0)
  c = characteristic(P)
  f = defining_polynomial((FiniteField(Int64(c),d))[1])
  for i=0:d
     setcoeff!(a, i, coeff(f,i))
  end
  return a
end


function NextIrreducible(x::PolyElem{T},U::AbstractArray) where T
 K = parent(x)
 i = 1
 while true
   if isirreducible(x)
      println("used $i rounds, irreducible poly $x")
      return x
   else 
      if R(i) == 0
      println("Next loop")
      x = x*randpoly(K,U)+K(1)
#       x=randpoly(K,U)+R(1)
      i = 1
      else
        i += 1
        x = x+K(1)
      end
   end
 end
end



function mod_poly(A::Generic.Mat{gfp_poly}, P::gfp_poly)
  a = array_mat(A)
  R = base_ring(A)
#  RP = ResidueField(R,P)
  RP = FiniteField(P, "s")[1]
  r = nrows(A)
  c = ncols(A)
  B = zero_matrix(RP,r,c)
  for i = 1:r
    for j = 1:c
	B[i,j] = RP(A[i,j])
    end
  end
  return B
end


function mod_poly2(A::Generic.Mat{gfp_poly}, P::gfp_poly)
  a = array_mat(A)
  R = base_ring(A)
  RP = ResidueField(R,P)
#  RP = FiniteField(P, "s")[1]
  r = nrows(A)
  c = ncols(A)
  B = zero_matrix(RP,r,c)
  for i = 1:r
    for j = 1:c
	B[i,j] = RP(A[i,j])
    end
  end
  return B
end




function lift_mat(A::Generic.Mat{Generic.ResF{gfp_fmpz_poly}})
  r = nrows(A)
  c = ncols(A)
  a = array_mat(A)
  P = parent(lift(a[1]))
  B = matrix(P,r,c,[lift(a[i]) for i=1:r*c])
  return B
end



function lift_mat(A::Generic.Mat{Generic.ResF{gfp_poly}})
  r = nrows(A)
  c = ncols(A)
  a = array_mat(A)
  P = parent(lift(a[1]))
  B = matrix(P,r,c,[lift(a[i]) for i=1:r*c])
  return B
end



function lift_(x::fq_nmod, K:: GFPPolyRing, d:: Int64)
  z = K()
  for i=0:d-1
    setcoeff!(z, i, coeff(x, i))
  end
  return z
end


function lift_mat(A::fq_nmod_mat, K:: GFPPolyRing, d:: Int64)
  r = nrows(A)
  c = ncols(A)
  a = array_mat(A)
  B = matrix(K,r,c,[lift_(a[i],K,d) for i=1:r*c])
  return B
end


function divexact_poly_mat(A::Generic.Mat{gfp_poly}, p::gfp_poly)
  for i=1:nrows(A)
    for j=1:ncols(A)
    A[i,j] = divexact(A[i,j],p)
    end
  end
end



function DetBound(A::Generic.Mat{gfp_poly})
 K = base_ring(A)
 n = nrows(A)
# a = Array(ZZ,n^2)
# b = Array(ZZ,n)
 a=[]
  for i=1:n
    for j=1:n
     push!(a,degree(A[i,j]))
    end
  end
 b=[]
  for i=0:n-1
     push!(b,maximum(a[1+i*n:n+i*n]))
  end

  return sum(b)
end





##############################################################################
#
#               Dixon Solver
#
##############################################################################

 
function DixonPolyDetGF(A::Generic.Mat{gfp_poly}, B::Generic.Mat{gfp_poly}, U::AbstractArray)
  r = nrows(A)
  c = ncols(A)
  K = base_ring(A)
@show  p = NextIrreducible(rand_pol(K,U),U)
#  p = rand_irreducible_pol(K, U)
  DB = 2*DetBound(A)
  d= degree(p)  
  Ap=mod_poly(A,p)
println("Inv")
@time IA=inv(Ap)
@time  ap=lift_mat(IA,K,d)
  sol = 0*B
  D = B
  pp = K(1)
  last_SOL = false
  nd = 0
  u = zero_matrix(K, r,1)
println("lifting")
  while true
    nd += 1
    y = ap*D
    y = lift_mat(mod_poly(y,p),K,d)
 #  y = lift_mat(mod_poly2(y,p))
    sol += y*pp
    pp *= p

    if d*nd > DB

println("used $nd $p-adic digits")
      return true
    end


   D = D - A*y
   divexact_poly_mat(D, p)
#    if nbits(pp) > 10000 # a safety device to avoid infinite loops
#      error("not work")
#    end
  end
end







#=example
julia> Zx,x=FlintZZ["x"]
julia> R=FlintFiniteField((3511))
julia> P,x=R["x"]
julia> A=rand_mat(MatrixSpace(P,10,10),10:15);
julia> b=rand_mat(MatrixSpace(P,10,1),10:15);

@time S = DixonPolyDetGF(A,b,5:8);
# S = DixonPolyDetGF(A,b,U ); U = degree range for irreducible poly for modular operation

=#
