m = Matrix.create_from_file_pair!("genes.Hs", "genes_phenes.Hs", :title => "genes_phenes.Hs")
n = m.copy_and_randomize.save!
o = Matrix.create_from_file_pair!("genes.Mm", "genes_phenes.Mm", :title => "genes_phenes.Mm", :column_species => "Mm")
p = o.copy_and_randomize.save!
q = Matrix.create_from_file_pair!("genes.Dm", "genes_phenes.Dm", :title => "genes_phenes.Dm", :column_species => "Dm")
r = q.copy_and_randomize.save!
s = Matrix.create_from_file_pair!("genes.Ce", "genes_phenes.Ce", :title => "genes_phenes.Ce", :column_species => "Ce")
t = s.copy_and_randomize.save!
u = Matrix.create_from_file_pair!("genes.Sc", "genes_phenes.Sc", :title => "genes_phenes.Sc", :column_species => "Sc")
v = u.copy_and_randomize.save!
w = Matrix.create_from_file_pair!("genes.At", "genes_phenes.At", :title => "genes_phenes.At", :column_species => "At")
x = w.copy_and_randomize.save!
