% Assembles two matrices with minimum or maximum centroid values, respectively,
% of the patch of elements surrounding each vertex of each element.
%
%===============================================================================
%> @file computeMinMaxV0TElementPatch.m
%>
%> @brief Assembles two matrices with minimum or maximum centroid values,
%>        respectively, of the patch of elements surrounding each vertex
%>        of each element.
%===============================================================================
%>
%> @brief Assembles two matrices with minimum or maximum centroid values,
%>        respectively, of the patch of elements surrounding each vertex
%>        of each element.
%>
%> For each vertex @f$\mathbf{x}_{ki}, i\in\{1,2,3\}@f$ of each triangle
%> @f$t_k@f$ it computes the minimum and maximum centroid values of a
%> function @f$c_h(\mathbf{x})@f$
%> @f[
%> \forall T_k \in \mathcal{T}_h \,, \forall i\in\{1,2,3\} \,, \quad
%> c_{ki}^\mathrm{min} := \min_{\{ T_l \in \mathcal{T}_h \,|\,
%>  \mathbf{x}_{ki} \in T \}} c_{l\mathrm{c}} \,,\quad
%> c_{ki}^\mathrm{max} := \max_{\{ T_l \in \mathcal{T}_h \,|\,
%>  \mathbf{x}_{ki} \in T \}} c_{l\mathrm{c}} \,,
%> @f]
%> where @f$c_{l\mathrm{c}} = c_h(\mathbf{x}_{lc})@f$ is the function value
%> in the centroid @f$\mathbf{x}_{lc}@f$ of triangle @f$T_l@f$.
%>
%> @param  g           The lists describing the geometric and topological 
%>                     properties of a triangulation (see 
%>                     <code>generateGridData()</code>) 
%>                     @f$[1 \times 1 \text{ struct}]@f$
%> @param  valCentroid The centroid values @f$c_{lc}@f$. @f$[K \times 1]@f$
%> @param  markV0TbdrD <code>logical</code> array that marks each triangles
%>                     (Dirichlet boundary) vertices on which the values given
%>                     in dataV0T should be included in the computation of
%>                     minimum/maximum @f$[K \times 3]@f$
%> @param  dataV0T     A list of values to be included in the determination
%>                     of minimum/maximum. @f$[K\times 3]@f$
%> @retval ret         The assembled matrices @f$[K \times 3]@f$ as
%>                     @f$[2 \times 1 \mathrm{cell}]@f$
%>
%> This file is part of FESTUNG
%>
%> @copyright 2014-2016 Florian Frank, Balthasar Reuter, Vadym Aizinger
%> 
%> @par License
%> @parblock
%> This program is free software: you can redistribute it and/or modify
%> it under the terms of the GNU General Public License as published by
%> the Free Software Foundation, either version 3 of the License, or
%> (at your option) any later version.
%>
%> This program is distributed in the hope that it will be useful,
%> but WITHOUT ANY WARRANTY; without even the implied warranty of
%> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%> GNU General Public License for more details.
%>
%> You should have received a copy of the GNU General Public License
%> along with this program.  If not, see <http://www.gnu.org/licenses/>.
%> @endparblock
%
function minMaxV0T = computeMinMaxV0TElementPatch(g, valCentroid, markV0TbdrD, dataV0T)
% Check function arguments that are directly used
assert(isequal(size(valCentroid), [g.numT 1]), 'Number of elements does not match size of valCentroid')
assert(isequal(size(markV0TbdrD), [g.numT 3]), 'Number of elements does not match size of markV0TbdrD')
assert(isequal(size(dataV0T), [g.numT 3]), 'Number of elements does not match size of dataV0T')

% Initialize return value: a 2x1-cell with a Kx3-array of minimum and 
% maximum values per vertex of each triangle
minMaxV0T = cell(2,1); 
minMaxV0T{1} = zeros(g.numT, 3); minMaxV0T{2} = zeros(g.numT, 3);

% To include only values from centroids and not the zeros introduced by
% multiplying with the markV0TV0T-matrix, all centroid values are
% shifted to positive/negative values, respectivly
shiftCentroidToPos = abs(min(valCentroid)) + 1;
shiftCentroidToNeg = abs(max(valCentroid)) + 1;
valCentroidPos = valCentroid + shiftCentroidToPos;
valCentroidNeg = valCentroid - shiftCentroidToNeg;

% Include boundary value on Dirichlet vertices into limiting procedure
valD = NaN(g.numT, 3);
valD(markV0TbdrD) = dataV0T(markV0TbdrD);

for i = 1 : 3
  % Mark all elements sharing i-th vertex
  markNbV0T = g.markV0TV0T{i, 1} | g.markV0TV0T{i, 2} | g.markV0TV0T{i, 3}; 
  
  % Fix a bug in GNU Octave 4.0.0's implementation of sparse matrix concatenation
  if exist('OCTAVE_VERSION','builtin')
    markNbV0T = markNbV0T + 0 * speye(size(markNbV0T, 1), size(markNbV0T, 2));
  end
  
  % Compute min/max per vertex as min/max of centroid values per vertex
  minMaxV0T{1}(:, i) = min(min(bsxfun(@times, markNbV0T, valCentroidNeg'), [], 2) ...
                          + shiftCentroidToNeg, valD(:, i));
  minMaxV0T{2}(:, i) = max(max(bsxfun(@times, markNbV0T, valCentroidPos'), [], 2) ...
                          - shiftCentroidToPos, valD(:, i));
end % for

end % function